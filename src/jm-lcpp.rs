use std::io::{stdin,Lines,StdinLock};

fn lcp(mut lines: Lines<StdinLock<'_>>) -> Option<String> {
    // longest common prefix
    let prefix_o = lines.next();
    if prefix_o.is_none()
        { return None; }

    let prefix_rs = prefix_o.unwrap();
    let mut prefix = prefix_rs.unwrap();

    let mut more_than_one = false;

    for ln in lines {
        let lns = ln.unwrap();
        if lns == prefix {
            // do not count duplicate lines as `more_than_one`.
            continue;
        }
        while !lns.starts_with(&prefix) {
            prefix.pop();
            if prefix.is_empty()
                { return None; }
        }

        more_than_one = true;
    }
    if ! more_than_one {
        return Some(prefix);
    }

    if !prefix.contains("/") {
        return None;
    }

    while !prefix.ends_with("/") {
        prefix.pop();
    }
    prefix.pop();
    return Some(prefix);
}

fn main() {
    let lcp = lcp(stdin().lines());
    if lcp.is_none() {
        return;
    }
    let lcp = lcp.unwrap();
    if !lcp.is_empty()
        { println!("{}", lcp); }
}
