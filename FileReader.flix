/*
 * Copyright 2024 Fridolin Karger
 * 
 * [TODO: do cpyright notice]
 *
*/

/// Represents a BufferedReader to provide an efficient and correctly encoded reading of characters into Strings
pub enum FileReader(##java.io.BufferedReader)

mod FileReader {

    ///
    /// Builds a BufferedReader which reads a file from a given path while buffering as much as sz
    ///
    /// path: String - should be a valid path
    /// encoding: Encoding - the encoding the file should be read as
    /// buffSize: Option[Int32] - the optional buffer size, if None uses a default-sized buffer
    ///
    pub def build(path: String, encoding: Encoding, buffSize: Option[Int32]): FileReader \ IO = 
        import new java.io.FileInputStream(String): ##java.io.FileInputStream \ IO as fileInputStream;
        import new java.io.InputStreamReader(##java.io.InputStream, ##java.nio.charset.Charset): ##java.io.InputStreamReader \ {} as newInputStreamReader;
        
        // let initBufferedReader = match buffSize {
        //     case None =>
        //         import new java.io.BufferedReader(##java.io.Reader): ##java.io.BufferedReader\ IO as bufferedReader;
        //         bufferedReader
        //     case Some(sz) =>
        //         import new java.io.BufferedReader(##java.io.Reader, Int32): ##java.io.BufferedReader\ IO as bufferedReaderSized;
        //         bufferedReaderSized(???)
        // };
        
        let charset = Encoding.toStandardCharset(encoding);

        let isReader = checked_cast(newInputStreamReader(
        checked_cast(fileInputStream(path
        )), charset));

        match buffSize {
            case None =>
                import new java.io.BufferedReader(##java.io.Reader): ##java.io.BufferedReader\ {} as bufferedReader;
                bufferedReader(isReader)
            case Some(sz) =>
                import new java.io.BufferedReader(##java.io.Reader, Int32): ##java.io.BufferedReader\ {} as bufferedReaderSized;
                bufferedReaderSized(isReader, sz)

        } |> FileReader

    ///
    /// Builds a BufferedReader which reads a file from a given path buffering as as much as sz
    ///
    pub def buildReader(path: String, encoding: Encoding): FileReader \ IO = build(path, encoding, None)

    ///
    /// Reads all the available lines from 
    /// 
    /// reader: FileReader - it should be created through .buildReader()
    ///
    /// @returns List containing all lines as String
    /// if the reading fails, returns an empty list
    pub def readLinesWith(reader: FileReader): List[String] \ IO = FileReader.readLinesWith_(reader, Nil)
   
    def readLinesWith_(reader: FileReader, result: List[String]): List[String] \ IO =
        match FileReader.nextLine(reader) {
            case Err(_) => result
            case Ok(line) => FileReader.readLinesWith_(reader, List.appendOne(result, line))
        }

    ///
    /// Reads the next line from
    ///
    /// reader: FileReader
    ///
    /// @returns 
    ///     Ok(String) containing all characters until either of (\n, \r, \r\n)
    ///     IOError
    ///
    pub def nextLine(reader: FileReader): Result[IOError, String] \ IO = 
        import java.io.BufferedReader.ready(): Bool \ IO;
        import java.io.BufferedReader.readLine(): String \ IO;
        let FileReader(fin) = reader;
        forM(
            readable <- IOError.tryCatch(_->{ready(fin)});
            result <- if (readable == false) Err(IOError.Generic("")) else 
                IOError.tryCatch(_->{readLine(fin)})
        ) yield result

    ///
    /// Resets the reader to the latest mark
    ///
    pub def reset(reader: FileReader): Result[IOError, Unit] \ IO =
        import java.io.BufferedReader.reset(): Unit \ IO;
        let FileReader(fin) = reader;
        IOError.tryCatch(_->{
            reset(fin)
        })

    ///
    /// Reads from 
    /// reader: FileReader - into
    /// buff: Array[Char, r] - with 
    /// offset: Int32 - with a count of
    /// len: Int32
    ///
    /// @returns Int32 as status code
    /// refer to https://docs.oracle.com/javase/8/docs/api/java/io/BufferedReader.html#read-char:A-int-int-
    /// really
    ///
    pub def read(reader: FileReader, buff: Array[Char, r], offset: Int32, len: Int32): Result[IOError, Int32] \ {IO, r} = 
        import java.io.BufferedReader.read(Array[Char, r], Int32, Int32): Int32 \ {IO, r} as readIntoArray;
        let FileReader(fin) = reader;
        IOError.tryCatch(_ -> {
            readIntoArray(fin, buff, offset, len)
        })
}

/// archaic test, refactor into own file
def test(): List[String] \ IO = FileReader.readLinesWith(FileReader.buildReader("utf8.test", Encoding.UTF_8))
