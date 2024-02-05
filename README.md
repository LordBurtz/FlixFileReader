Ever stared at bytes your flix program just wouldn't rightly read from a file?  
Ever wanted to just read a file line by line as it is just so convenient?  
Say no more..

# FileReader.flix
### What?
Wrapping `java.io.BufferedReader` to provide reading functionality beyond your wildest dreams. Effectively this means you can now read your files the way you want in any encoding you want, even by lines, if you want.

### How?
Just like this
```scala
def testReadingLines(): Unit \ IO = 
    // Open your file (e.g. encoded in utf8) through the FileReader
    let reader = FileReader.buildReader("utf8.test", Encoding.UTF_8);
    
    // Read all lines
    let lines: List[String] = FileReader.readLinesWith(reader);
    ...
```

### Why?
To learn flix I started doing AoC 2023 but quickly ran into the issue that reading files is kinda tedious. So I began writing a solution for that problem.  
At the same time one of my resolutions for '24 is contributing to one niche language and so here we are, first attempt.