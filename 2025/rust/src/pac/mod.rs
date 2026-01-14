use std::env;
use std::fs::File;
use std::io::{self, BufRead, BufReader, Lines, Read};

pub enum ReadInput {
    Stdin,
    File(std::fs::File),
}

impl Read for ReadInput {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        match self {
            ReadInput::Stdin => std::io::stdin().read(buf),
            ReadInput::File(inner) => inner.read(buf),
        }
    }
}

impl ReadInput {
    pub fn size(&self) -> Option<usize> {
        match self {
            ReadInput::File(inner) => {
                if let Ok(metatada) = inner.metadata() {
                    Some(metatada.len() as usize)
                } else {
                    None
                }
            },
            ReadInput::Stdin => None,
        }
    }
}

pub struct StdinOrFile;

impl StdinOrFile {
    fn get_fin() -> ReadInput {
        let arguments: Vec<String> = env::args().collect();

        match arguments.get(1) {
            Some(filename) => File::open(filename).map(ReadInput::File).unwrap(),
            _ => ReadInput::Stdin,
        }
    }

    pub fn buf_reader() -> BufReader<ReadInput> {
        let fin = Self::get_fin();

        BufReader::new(fin)
    }

    pub fn lines() -> Lines<BufReader<ReadInput>> {
        StdinOrFile::buf_reader().lines()
    }

    pub fn read_binary() ->Vec<u8>{
        let mut fin = Self::get_fin();

        let mut buffer;
        if let Some(size) = fin.size() {
            buffer = vec![0; size];
            fin.read(&mut buffer).expect("Error reading file content");
        } else {
            eprintln!("WARN: filesize not available");
            buffer = Vec::new();
            fin.read_to_end(& mut buffer).expect("Error reading to end");
        }
        buffer
    }
}
