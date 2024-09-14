use std::io;
use std::path::Path;
use std::path::PathBuf;
use std::path::Component;

fn main() {
    let stdin = io::stdin();
    let lines: Vec<String> = stdin.lines().map(|x| x.unwrap()).collect();

    if lines.len() == 0 {
        return;
    }else if lines.len() == 1 {
        println!("{}", lines[0]);
        return;
    }

    let paths: Vec<Vec<Component>> = (0..lines.len())
        .map(|i| Path::new(&lines[i]).components().collect())
        .collect();

    let min = paths.iter().min_by(|x, y| x.len().cmp(&y.len())).unwrap();
    let max = paths.iter().max_by(|x, y| x.len().cmp(&y.len())).unwrap();

    let lcpp = min.iter()
            .zip(max.iter())
            .take_while(|(x, y)| x==y)
            .map(|(x, _) | x)
            .fold(PathBuf::new(), |x, y| x.join(y));

    let lcpp_s = lcpp.to_str().unwrap();
    if lcpp_s != "" {
        println!("{}", lcpp.to_str().unwrap());
    }
}
