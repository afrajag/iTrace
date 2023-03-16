//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

/*
 final class Parser {
 var bf: StreamReader
 var lineTokens: String[]
 var index: Int32 = 0

 init(_ filename: String) {
 	self.init(: File.OpenRead(filename))
 }

 init(_ stream: Stream) {
 	bf = StreamReader(stream)
 	lineTokens = String[](repeating: 0, count: 0)
 	index = 0
 }

 func close() {
 	// if (file != null)
 	//     file.close();
 	bf.Close()
 	bf = nil
 }

 func getNextToken() -> String {
 	while true {
 		var tok: String = fetchNextToken()
 		if tok == nil {
 			return nil
 		}
 		if tok == " /* " {
  			repeat {tok = fetchNextToken()
  				if tok == nil {
  					return nil
  				}
  			} while tok != " */ "} else {
 			return tok
 		}
 	}}

 func peekNextToken(_ tok: String) -> Bool {
 	while true {
 		var t: String = fetchNextToken()
 		if t == nil {
 			return false
 		}
 		//  nothing left
 		if t == " /* " {
  			repeat {t = fetchNextToken()
  				if t == nil {
  					return false
  				}
  				//  nothing left
  			} while t != " */ "} else {
 			if t == tok {
 				//  we found the right token, keep parsing
 				return true
 			} else {
 				//  rewind the token so we can try again
 				dec(index)
 				return false
 			}
 		}
 	}}

 func fetchNextToken() -> String {
 	if bf == nil {
 		return nil
 	}
 	while true {
 		if index < lineTokens.count {
 			return lineTokens[index]
 		} else {
 			if getNextLine() {
 				return nil
 			}
 		}
 	}}

 func getNextLine() -> Bool {
 	var line: String = bf.ReadLine()
 	if line == nil {
 		return false
 	}
 	var tokenList: Array<String> = Array<String>()
 	var current: String = String.Empty
 	var inQuotes: Bool = false
 	for i in 0 ... line.count - 1 {
 		var c: Char = line[i]
 		if (current.isEmpty) & ((c == "%") | (c == "#")) {
 			break
 		}
 		var quote: Bool = c == "\""
 		inQuotes = inQuotes ^^ quote
 		if quote & (inQuotes | Char.IsWhiteSpace(c)) {
 			current = current + c
 		} else {
 			if current.count > 0 {
 				tokenList.Add(current)
 				current = String.Empty
 			}
 		}
 	}
 	if current.count > 0 {
 		tokenList.Add(current)
 	}
 	lineTokens = tokenList.ToArray()
 	index = 0
 	return true
 }

 func getNextCodeBlock() -> String {
 	//  read a java code block
 	var code: String = String.Empty
 	checkNextToken("")
 	while true {
 		var line: String

 line = bf.ReadLine()

 			//print(e.StackTrace)
 			//return nil

 		if line.Trim() == "" {
 			return code
 		}
 		code = code + line + Environment.NewLine
 	}}

 func getNextbool() -> Bool {
 	return Bool.Parse(getNextToken())
 }

 func getNextInt() -> Int32 {
 	return Int32.Parse(getNextToken())
 }

 func getNextFloat() -> Float {
 	return Float.Parse(getNextToken(), System.Globalization.CultureInfo.InvariantCulture)
 }

 func checkNextToken(_ token: String) {
 	var found: String = getNextToken()
 	if token != found {
 		close()
 		throw ParserException(token, found)
 	}
 }

 final class ParserException : Exception {
 	init(_ token: String, _ found: String) {
 		super.init(: String.Format("Expecting \(xxx) found \(xxx)", token, found))
 	}
 }
 }
 */
