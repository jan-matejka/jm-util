use std::io::{stdin,Lines,StdinLock};

fn lcp(mut lines: Lines<StdinLock<'_>>) -> Option<String> {
    // longest common prefix
    let prefix_o = lines.next();
    if prefix_o.is_none()
        { return None; }

    let prefix_rs = prefix_o.unwrap();
    let mut prefix = prefix_rs.unwrap();

    for ln in lines {
        let lns = ln.unwrap();
        while !lns.starts_with(&prefix) {
            prefix.pop();
            if prefix.is_empty()
                { return None; }
        }
    }
    return Some(prefix);
}

fn drop_trailing_basename(s: &mut String) {
    if !s.contains("/")
        { s.truncate(0); return; }

    while !s.ends_with("/")
        { s.pop(); }
    s.pop();
}

fn main() {
    let lcp = lcp(stdin().lines());
    if lcp.is_none() {
        // println!("none");
        return;
    }
    let mut lcp = lcp.unwrap();
    drop_trailing_basename(&mut lcp);
    if !lcp.is_empty()
        { println!("{}", lcp); }
}
