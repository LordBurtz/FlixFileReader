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
