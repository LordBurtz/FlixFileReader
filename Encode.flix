// Copyright Fridolin Karger 2024
// referencing those fields
// https://docs.oracle.com/javase/8/docs/api/java/nio/charset/StandardCharsets.html
pub enum Encoding with ToString {
    case ISO_8859_1,
    case US_ASCII,
    case UTF_8,
    case UTF_16,
    case UTF_16BE,
    case UTF_16LE
}

mod Encoding {
    pub def int8asAscii(i: Int8): Option[Char] = 
        forM (chars <- i |> Int8.toInt32 |> CodePoint.toChars)
            yield Vector.get(0, chars)

    pub def toStandardCharset(encoding: Encoding): ##java.nio.charset.Charset = 
        match encoding {
            case Encoding.ISO_8859_1 =>
                import static get java.nio.charset.StandardCharsets.ISO_8859_1: ##java.nio.charset.Charset \ {} as getISO_8859_1;
                getISO_8859_1()
            case Encoding.US_ASCII =>
                import static get java.nio.charset.StandardCharsets.US_ASCII: ##java.nio.charset.Charset \ {} as getUS_ASCII;
                getUS_ASCII()
            case Encoding.UTF_8 =>
                import static get java.nio.charset.StandardCharsets.UTF_8: ##java.nio.charset.Charset \ {} as getUTF_8;
                getUTF_8()
            case Encoding.UTF_16 =>
                import static get java.nio.charset.StandardCharsets.UTF_16: ##java.nio.charset.Charset \ {} as getUTF_16;
                getUTF_16()
            case Encoding.UTF_16BE =>
                import static get java.nio.charset.StandardCharsets.UTF_16BE: ##java.nio.charset.Charset \ {} as getUTF_16BE;
                getUTF_16BE()
            case Encoding.UTF_16LE =>
                import static get java.nio.charset.StandardCharsets.UTF_16LE: ##java.nio.charset.Charset \ {} as getUTF_16LE;
                getUTF_16LE()
        }
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

def testReadLines(): Result[IOError, Int32] \ IO = 
    forM(
        file <- File.open("utf8.test", File.Mode.ReadOnly);
        _ <- File.readLines(file, Encoding.US_ASCII)
    ) yield 1
    

