// Copyright Fridolin Karger 2024
// referencing those fields
// https://docs.oracle.com/javase/8/docs/api/java/nio/charset/StandardCharsets.html
pub enum Encoding with ToString {
    case US_ASCII,
    case UTF_8,
    case UTF_16,
    case UTF_16BE,
    case UTF_16LE,
    case ISO_8859_1
}

mod Encoding {
    pub def us_ascii(): Encoding = Encoding.US_ASCII
    pub def utf8(): Encoding = Encoding.UTF_8
    pub def utf16(): Encoding = Encoding.UTF_16

    pub def int8asAscii(i: Int8): Option[Char] = 
        forM (chars <- i |> Int8.toInt32 |> CodePoint.toChars)
            yield Vector.get(0, chars)
}

mod File {
    pub def readLines(file: File, _: Encoding): Result[IOError, List[String]] \ IO =
        region rc {
            forM (
                len <- File.length(file);
                arrLen <- Int64.tryToInt32(len) |> Option.toOk(IOError.Generic(""));
                arr <- Ok(Array.new(rc, arrLen));
                _ <- File.readFully!(arr, file)
            ) yield arr 
                |> arrAsChar 
                |> List.subgroupBy(x -> x == '\n')
                |> List.map(line -> List.fold(List.map(Char.toString, line)))
                |> List.map(line -> line + "++\n")
                |> debug!
        }

    def arrAsChar(arr: Array[Int8, rc]): List[Char] \ rc =
        region local {
            let result = Array.map(local, Encoding.int8asAscii, arr);
            Array.toList(result) 
            |> List.filterAndLiftOption
        }

    
}

mod List {

    pub def appendOne(list: List[t], item: t): List[t] = list ::: (item :: Nil)

    // maps a List[Option[a]] to List[a]
    // filters out None
    pub def filterAndLiftOption(list: List[Option[t]]): List[t] = match list {
        case Nil => Nil,
        case Some(v) :: xs => v :: List.filterAndLiftOption(xs),
        case _ :: xs => List.filterAndLiftOption(xs)
    }

    // maps a List[a] to a List[b] using f
    // if predicate pred is satisfied
    pub def filterAndMap(pred: a -> Bool, f: a -> b, lst: List[a]): List[b] = match lst {
        case Nil => Nil,
        case x :: xs if pred(x) => f(x) :: List.filterAndMap(pred, f, xs),
        case _ :: xs => List.filterAndMap(pred, f, xs)
    }

    // splits a List[a] into a list of subgroups: List[List[a]]
    // if the predicate is satisfied by omitting the delimiter
    pub def subgroupBy(pred: a -> Bool, list: List[a]): List[List[a]] = List.splitAllOn(pred, list, Nil)

    def splitAllOn(pred: a -> Bool, list: List[a], curr: List[a]): List[List[a]] = match list {
        case Nil => Nil,
        case x :: xs if pred(x) => List.point(curr) ::: List.splitAllOn(pred, xs, Nil)
        case x :: xs => List.splitAllOn(pred, xs, List.appendOne(curr, x))
    }
}

pub enum FileReader(##java.io.BufferedReader)

def test(): List[String] \ IO = FileReader.readLinesAs(FileReader.buildReader("utf8.test", Encoding.utf8()), Nil)

mod FileReader {

    pub def buildReader(path: String, encoding: Encoding): FileReader \ IO = 
        import new java.io.FileInputStream(String): ##java.io.FileInputStream \ IO as fileInputStream;
        import new java.io.InputStreamReader(##java.io.InputStream, ##java.nio.charset.Charset): ##java.io.InputStreamReader \ IO as newInputStreamReader;
        import new java.io.BufferedReader(##java.io.Reader): ##java.io.BufferedReader\ IO as bufferedReader;
        
        let charset = match encoding {
            case Encoding.UTF_8 =>
                import static get java.nio.charset.StandardCharsets.UTF_8: ##java.nio.charset.Charset \ IO as getUTF_8;
                getUTF_8()
            case Encoding.UTF_16 =>
                import static get java.nio.charset.StandardCharsets.UTF_16: ##java.nio.charset.Charset \ IO as getUTF_16;
                getUTF_16()
            case Encoding.US_ASCII =>
                import static get java.nio.charset.StandardCharsets.US_ASCII: ##java.nio.charset.Charset \ IO as getUS_ASCII;
                getUS_ASCII()
            case _ => bug!("Encoding (${encoding}) not implemented yet!")
        };

        bufferedReader(
        checked_cast(newInputStreamReader(
        checked_cast(fileInputStream(path
        )), charset))) 
        |> FileReader


    pub def readLinesAs(reader: FileReader, result: List[String]): List[String] \ IO =
        import java.io.BufferedReader.ready(): Bool \ IO;
        import java.io.BufferedReader.readLine(): String \ IO;
        let FileReader(fin) = reader;
        if (debug!(ready(fin)) == false) result else FileReader.readLinesAs(reader, List.appendOne(result, readLine(fin)))
}

def testReadLines(): Result[IOError, Int32] \ IO = 
    forM(
        file <- File.open("utf8.test", File.Mode.ReadOnly);
        _ <- File.readLines(file, Encoding.US_ASCII)
    ) yield 1
    

