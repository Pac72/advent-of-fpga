use aoc_2025_03::pac::StdinOrFile;

fn bank_joltage(line: &str) -> u32 {
    let max1 = line[..line.len() - 1].bytes().max().unwrap();

    let idx1 = line.bytes()
        .enumerate()
        .find(|(_, v)| *v == max1)
        .unwrap().0;

    let max2 = line[idx1 + 1..].bytes().max().unwrap();

    let c1 = max1 as u32 - '0' as u32;
    let c2 = max2 as u32 - '0' as u32;

    c1*10 + c2
}

fn main() {
    let mut result = 0;

    for line in StdinOrFile::lines().map_while(Result::ok) {
        result += bank_joltage(&line);
    }

    println!("{result}");
}
