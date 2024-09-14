use std::io;
use std::path::Path;
use std::path::Component;
use std::path::PathBuf;

/*
fn lcpp<'x>(x: &'x Vec<Component<'x>>, y: &Vec<Component>) -> PathBuf {
    let mut p = PathBuf::new();
    for (x, y) in x.iter().zip(y.iter()) {
        if x == y {
            p.push(x);
        }else{
            break;
        }
    }

    return p;
}*/


fn lcpp<'x>(x: Vec<Component<'x>>, y: Vec<Component>) -> Vec<Component<'x>> {
    let lcpp:Vec<_> = x.iter()
            .zip(y.iter())
            .take_while(|(x, y)| x==y)
            .map(|(x, _) | *x)
            .collect();
    return lcpp.clone();
}


/*
fn lcpp2<T: Eq>(x: Vec<T>, y: Vec<T>) -> Vec<T> {
    let lcpp:Vec<T> = x.iter()
            .zip(y.iter())
            .take_while(|(x, y)| x==y)
            .map(|(x, _) | *x)
            .collect();
    return lcpp;
}
*/

/*
fn lcpp_r<'x>(xs: &'x Vec<Vec<Component>>) -> Vec<Component<'x>> {
    if xs.len() > 2 {
        let x1 = xs[0..(xs.len())/2].to_vec();
        let x = lcpp_r(&x1);
        let y1 = xs[((xs.len())/2)..].to_vec();
        let y = lcpp_r(&y1);
        return lcpp(&x, &y);
    }else if xs.len() == 2 {
        return lcpp(&xs[0], &xs[1]);
    }else if xs.len() == 1 {
        return xs[0];
    }else{
        return Vec::new();
    }
}
*/

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
        /*
        compare = Vec::new();
        compare.append(&mut paths.iter().filter(|x| x.len() == min).map(|x| *x).collect());
        compare.append(&mut paths.iter().filter(|x| x.len() == max).map(|x| *x).collect());
        */
    }

    /*
    let mut refs: VecDeque<&Vec<Component>> = VecDeque::new();
    for x in compare.iter_mut() {
        refs.push_back(x);
    }
    // refs: VecDeque<&Vec<Component>> = VecDeque::from(&mut compare.iter().collect::<Vec<&Vec<Component>>>());
    while refs.len() > 1 {
        let new = lcpp(refs.pop_front().unwrap(), refs.pop_front().unwrap());
        &mut compare.push(new);
        refs.push_back(&compare[compare.len()]);
    }
    */

    while compare.len() > 1 {
        let x = compare.pop().unwrap();
        let y = compare.pop().unwrap();
        let new = lcpp(x, y);
        compare.push(new);
    }

    // let components = refs.pop_front().unwrap();
    let components = compare.pop().unwrap();
    let rs = components.iter().fold(PathBuf::new(), |x, y| x.join(y));
    let r = rs.to_str().unwrap();
    if r != "" {
        println!("{}", r);
    }

    /*
    let r = lcpp_r(&compare);
    let rs = r.iter().fold(PathBuf::new(), |x, y| x.join(y));
    let r = rs.to_str().unwrap();
    if r != "" {
        println!("{}", r);
    }*/
}
