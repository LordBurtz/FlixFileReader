/*
 * Copyright 2024 Fridolin Karger
 * 
 * [TODO: do cpyright notice]
 *
*/

/// Represents a BufferedReader to provide an efficient and correctly encoded reading of characters into Strings
/// Wrapping java.io.BufferedReader to provide additional functionality such as
/// reading line by line, by character, skipping ahead, resetting, skipping
/// while supporting all native java encodings
pub enum FileReader(##java.io.BufferedReader)

mod FileReader {

    /// Builds a BufferedReader from 
    /// 
    /// file: File - file to be opened in
    /// encoding: Encoding - with a buffered Size of
    /// buffSize: Option[Int32]
    ///
    pub def buildFromFileSized(file: File, encoding: Encoding, buffSize: Option[Int32]): FileReader \ IO = 
        import java.io.RandomAccessFile.getFD(): ##java.io.FileDescriptor \ IO;
        import new java.io.FileInputStream(##java.io.FileDescriptor): ##java.io.FileInputStream \ IO as fileInputStream;

        let File.File(f) = file;
        build_(checked_cast(fileInputStream(getFD(f))), encoding, buffSize)

    ///
    /// TODO: documentation
    ///
    pub def buildFromFile(file: File, encoding: Encoding): FileReader \ IO = buildFromFileSized(file, encoding, None)

    def build_(inputStr: ##java.io.InputStream, encoding: Encoding, buffSize: Option[Int32]): FileReader \ {} = 
        import new java.io.InputStreamReader(##java.io.InputStream, ##java.nio.charset.Charset): ##java.io.InputStreamReader \ {} as newInputStreamReader;
        
        let charset = Encoding.toStandardCharset(encoding);
        let isReader = checked_cast(newInputStreamReader(inputStr, charset));

        match buffSize {
            case None =>
                import new java.io.BufferedReader(##java.io.Reader): ##java.io.BufferedReader\ {} as bufferedReader;
                bufferedReader(isReader)
            case Some(sz) =>
                import new java.io.BufferedReader(##java.io.Reader, Int32): ##java.io.BufferedReader\ {} as bufferedReaderSized;
                bufferedReaderSized(isReader, sz)

        } |> FileReader



    ///
    /// Builds a BufferedReader which reads a file from a given path while buffering as much as sz
    ///
    /// path: String - should be a valid path
    /// encoding: Encoding - the encoding the file should be read as
    /// buffSize: Option[Int32] - the optional buffer size, if None uses a default-sized buffer
    ///
    pub def buildFromPathSized(path: String, encoding: Encoding, buffSize: Option[Int32]): FileReader \ IO = 
        import new java.io.FileInputStream(String): ##java.io.FileInputStream \ IO as fileInputStream;
        build_(checked_cast(fileInputStream(path)), encoding, buffSize)

    ///
    /// Builds a BufferedReader which reads a file from a given path buffering as as much as sz
    ///
    pub def buildFromPath(path: String, encoding: Encoding): FileReader \ IO = buildFromPathSized(path, encoding, None)

    ///
    /// Reads all the available lines from 
    /// 
    /// reader: FileReader - it should be created through .buildReader()
    ///
    /// @returns List containing all lines as String
    /// if the reading fails (e.g. file closed), returns an empty list
    ///
    pub def readLinesWith(reader: FileReader): List[String] \ IO = FileReader.readLinesWith_(reader, Nil)
   
   /// helper method
    def readLinesWith_(reader: FileReader, result: List[String]): List[String] \ IO =
        match FileReader.nextLine(reader) {
            case Err(_) => Nil
            case Ok(line) => FileReader.readLinesWith_(reader, List.append(result, line :: Nil))
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
        // TODO: find more elegant way, is basically a monad 
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

    ///
    /// Skips ahead
    /// amount: Int64 - bytes
    ///
    pub def skip(reader: FileReader, amount: Int64): Result[IOError, Int64] \ IO = 
        import java.io.BufferedReader.skip(Int64): Int64 \ IO;
        let FileReader(fin) = reader;
        IOError.tryCatch(_ -> {
            skip(fin, amount)
        })
}

/// archaic test, refactor into own file
def test(): List[String] \ IO = FileReader.readLinesWith(FileReader.buildFromPath("utf8.test", Encoding.UTF_8))

def testDoubleOpen(): Result[IOError, List[String]] \ IO = forM (
    file <- File.open("utf8.test", File.Mode.ReadOnly);
    _ <- File.close!(file);
    // _ <- File.readChar!(file);
    reader <- Ok(FileReader.buildFromFileSized(file, Encoding.UTF_8, None));
    // lines <- Ok("a" :: "b" :: Nil)
    lines <- FileReader.nextLine(reader)
) yield lines :: Nil
