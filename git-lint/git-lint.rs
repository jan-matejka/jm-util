use std::convert::TryFrom;
use std::env;
use std::error;
use std::fmt;
use std::process;
use std::sync::OnceLock;

use anyhow::Result;
use bon::Builder;
use bstr::ByteSlice;
use gix::revision::walk::Info;
use gix::Repository;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum MessageError {
    #[error("commit title is not valid UTF-8")]
    InvalidUtf8(#[from] bstr::Utf8Error),

    #[error("failed to parse conventional commit header: {0}")]
    Parse(String),
}

/// Returns commit ids for a rev-spec range like "main..feature" or "main...feature".
fn commits_in_range<'repo>(repo: &'repo Repository, range: &'repo str) -> Result<Vec<Info<'repo>>> {
    let spec = repo.rev_parse(range)?.detach();

    let ids = match spec {
        gix::revision::plumbing::Spec::Include(id) => {
            repo.rev_walk(Some(id)).all()?.collect::<Result<_, _>>()?
        }
        gix::revision::plumbing::Spec::Range { from, to } => repo
            .rev_walk(Some(to))
            .with_hidden(Some(from))
            .all()?
            .collect::<Result<_, _>>()?,
        gix::revision::plumbing::Spec::Merge { theirs, ours } => {
            let base = repo.merge_base(theirs, ours)?.detach();
            repo.rev_walk([theirs, ours])
                .with_hidden(Some(base))
                .all()?
                .collect::<Result<_, _>>()?
        }
        other => anyhow::bail!("unsupported range kind: {other:?}"),
    };

    Ok(ids)
}

#[derive(Default, Debug, PartialEq, Builder)]
struct Message<'a> {
    #[builder(default = "")]
    cc: &'a str,
    #[builder(default = "")]
    scope: &'a str,
    #[builder(default = "")]
    aspect: &'a str,
    #[builder(default = "")]
    msg: &'a str,
}

impl<'a> fmt::Display for Message<'a> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        if !self.cc.is_empty() {
            write!(f, "{}", self.cc)?;
            if !self.scope.is_empty() {
                write!(f, "({}", self.scope)?;
                if !self.aspect.is_empty() {
                    write!(f, "#{}", self.aspect)?;
                }
                write!(f, ")")?;
            }
            write!(f, ": ")?;
        }
        write!(f, "{}", self.msg)
    }
}

impl<'a> TryFrom<&'a str> for Message<'a> {
    type Error = MessageError;

    fn try_from(title: &'a str) -> Result<Self, Self::Error> {
        use nom::{
            branch::alt,
            bytes::complete::tag,
            character::complete::{alpha1, char, digit1},
            combinator::{all_consuming, opt, rest},
            sequence::{delimited, preceded, terminated},
            Parser,
        };

        let aspect = preceded(tag("#"), alt((alpha1, digit1)));
        let scope = delimited(char('('), (alpha1, opt(aspect)), char(')'));
        let cc_type = alt((alpha1, digit1));
        let cc = terminated((cc_type, opt(scope)), (tag(":"), opt(char(' '))));

        let mut parser = all_consuming((opt(cc), rest));

        let parsed: nom::IResult<&str, _> = parser.parse(title);
        let (_, (cc, msg)) = parsed
            .as_ref()
            .map_err(|e| MessageError::Parse(e.to_string()))?;
        let (cc, scope) = cc.unwrap_or(("", None));
        let (scope, aspect) = scope.unwrap_or(("", None));
        let aspect = aspect.unwrap_or("");

        // println!("{:?}", parsed);
        return Ok(Message {
            cc: cc,
            scope: scope,
            aspect: aspect,
            msg: msg,
        });
    }
}

#[derive(Builder, Debug, Default)]
struct Context<'a> {
    commit: String,
    title: &'a str,
    msg: Message<'a>,
}

#[derive(Debug)]
struct Violation {
    rule: &'static str,
    commit: String,
    subject: String,
    message: String,
}

impl<'a> fmt::Display for Violation {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(
            f,
            "{} violation at {} by {} {}",
            self.rule, self.commit, self.subject, self.message
        )
    }
}

trait Validator {
    fn name(&self) -> &'static str;
    fn check<'a>(&self, ctx: &'a Context) -> Option<Violation>;
}

#[derive(Debug)]
struct TitleMaxLength {
    max: usize,
}

impl Validator for TitleMaxLength {
    fn name(&self) -> &'static str {
        "title-max-length"
    }

    fn check<'a>(&self, ctx: &'a Context) -> Option<Violation> {
        if ctx.title.len() > self.max {
            Some(Violation {
                rule: self.name(),
                commit: ctx.commit.to_string(),
                subject: ctx.title.to_string(),
                message: format!("max={}", self.max),
            })
        } else {
            None
        }
    }
}

static SELF: OnceLock<String> = OnceLock::new();

fn init_self(mut argv0: String) {
    let idx = argv0.rfind('/');
    if idx.is_some() {
        argv0 = argv0[(idx.unwrap() + 1)..].to_string();
    }
    SELF.set(argv0).ok();
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let repo = gix::discover(".")?;
    let mut args = env::args();
    init_self(args.next().unwrap());

    let validators: Vec<Box<dyn Validator>> = vec![Box::new(TitleMaxLength { max: 80 })];

    let rev = args.next().unwrap();
    let commits = commits_in_range(&repo, rev.as_str())?;
    let mut violations: Vec<Violation> = vec![];
    for info in commits {
        let commit = info.object()?;
        let message = commit.message()?;
        let title: &str = message.title.to_str()?.trim_end();
        let msg = Message::try_from(title)?;
        let ctx = Context::builder()
            .commit(info.id.to_string())
            .title(title)
            .msg(msg)
            .build();

        violations.extend(
            validators.iter().filter_map(|v| v.check(&ctx)).collect::<Vec<_>>()
        );
    }

    if !violations.is_empty() {
        let self_ = SELF.get().unwrap();
        for v in violations {
            eprintln!("{}: {}", self_, v);
        }
        process::exit(1);
    }

    Ok(())
}

#[cfg(test)]
pub mod tests {
    use super::*;

    #[test]
    fn display_formats_conventional_commit() {
        assert_eq!(
            Message::builder()
                .cc("feat")
                .scope("parser")
                .aspect("123")
                .msg("add scopes")
                .build()
                .to_string(),
            "feat(parser#123): add scopes"
        );
        assert_eq!(
            Message::builder()
                .cc("fix")
                .scope("auth")
                .msg("handle expired tokens")
                .build()
                .to_string(),
            "fix(auth): handle expired tokens"
        );
        assert_eq!(
            Message::builder()
                .cc("docs")
                .msg("update readme")
                .build()
                .to_string(),
            "docs: update readme"
        );
        assert_eq!(
            Message::builder().msg("plain message").build().to_string(),
            "plain message"
        );
        assert_eq!(Message::builder().build().to_string(), "");
    }

    #[test]
    fn test_try_from() -> Result<(), Box<dyn error::Error>> {
        assert_eq!(
            Message::try_from("foo")?,
            Message::builder().msg("foo").build()
        );
        assert_eq!(
            Message::try_from("foo:")?,
            Message::builder().cc("foo").build()
        );
        assert_eq!(
            Message::try_from("foo: ")?,
            Message::builder().cc("foo").build()
        );
        assert_eq!(
            Message::try_from("foo(bar):")?,
            Message::builder().cc("foo").scope("bar").build()
        );
        assert_eq!(
            Message::try_from("docs: update readme")?,
            Message::builder().cc("docs").msg("update readme").build()
        );
        assert_eq!(
            Message::try_from("fix(auth): handle expired tokens")?,
            Message::builder()
                .cc("fix")
                .scope("auth")
                .msg("handle expired tokens")
                .build()
        );
        assert_eq!(
            Message::try_from("feat(parser#123): add support for scopes")?,
            Message::builder()
                .cc("feat")
                .scope("parser")
                .aspect("123")
                .msg("add support for scopes")
                .build()
        );
        assert_eq!(
            Message::try_from("42: numeric type edge case")?,
            Message::builder()
                .cc("42")
                .msg("numeric type edge case")
                .build()
        );
        assert_eq!(
            Message::try_from("chore: ")?,
            Message::builder().cc("chore").build()
        );
        assert_eq!(
            Message::try_from("feat(parser)no colon here")?,
            Message::builder().msg("feat(parser)no colon here").build()
        );
        assert_eq!(
            Message::try_from("feat(parser: missing close paren")?,
            Message::builder()
                .msg("feat(parser: missing close paren")
                .build()
        );
        assert_eq!(
            Message::try_from(": no type given")?,
            Message::builder().msg(": no type given").build()
        );
        Ok(())
    }
}
