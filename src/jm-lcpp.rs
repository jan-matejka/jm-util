use std::io;
use std::path::Path;
use std::path::Component;
use std::path::PathBuf;

fn lcpp<'x>(x: Vec<Component<'x>>, y: Vec<Component>) -> Vec<Component<'x>> {
    let lcpp:Vec<_> = x.iter()
            .zip(y.iter())
            .take_while(|(x, y)| x==y)
            .map(|(x, _) | *x)
            .collect();
    return lcpp.clone();
}

fn main() {
    let stdin = io::stdin();
    let lines: Vec<String> = stdin.lines().map(|x| x.unwrap()).collect();

    if lines.len() == 0 {
        return;
    }else if lines.len() == 1 {
        println!("{}", lines[0]);
        return;
    }

    let mut paths: Vec<Vec<Component>> = (0..lines.len())
        .map(|i| Path::new(&lines[i]).components().collect())
        .collect();

    let lens: Vec<usize> = paths.iter().map(|x| x.len()).collect();
    let min:usize = *lens.iter().min().unwrap();
    let max:usize = *lens.iter().max().unwrap();

    let mut compare: Vec<Vec<Component>>;
    if min == max {
        compare = paths;
    }else{
        // Note we need to select and compare all the minimal and maximal elements here.
        // (Instead of picking one at random as they are not interchangeable as is the case in the
        // longest common string prefix problem).
        compare = Vec::new();
        let mut i = 0;
        while i < paths.len() {
            let minmax = vec![min, max];
            if minmax.contains(&paths[i].len()) {
                compare.push(paths.remove(i));
            }else{
                i+=1;
            }
        }
    }

    while compare.len() > 1 {
        let x = compare.pop().unwrap();
        let y = compare.pop().unwrap();
        let new = lcpp(x, y);
        compare.push(new);
    }

    let components = compare.pop().unwrap();
    let rs = components.iter().fold(PathBuf::new(), |x, y| x.join(y));
    let r = rs.to_str().unwrap();
    if r != "" {
        println!("{}", r);
    }
}
