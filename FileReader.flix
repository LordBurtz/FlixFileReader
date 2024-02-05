mod File2 {
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