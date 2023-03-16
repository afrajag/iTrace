//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol BitmapWriter: Initializable {
    // This method will be called before writing begins. It is used to set
    // common attributes to file writers. Currently supported keywords include:
    // <ul>
    // <li>"compression"</li>
    // <li>"channeltype": "byte", "short", "half", "float"</li>
    // </ul>
    // Note that this method should not fail if its input is not supported or
    // invalid. It should gracefully ignore the error and keep its default
    // state.
    //
    // @param option
    // @param value
    func configure(_ option: String, _ value: String)

    // Open a handle to the specified file for writing. If the writer buffers
    // the image and writes it on close, then the filename should be stored.
    //
    // @param filename filename to write the bitmap to
    // @throws IOException thrown if an I/O error occurs
    func openFile(_ filename: String) throws

    // Write the bitmap header. This may be defered if the image is buffered for
    // writing all at once on close. Note that if tile size is positive, data
    // sent to this final class is guarenteed to arrive in tiles of that size (except
    // at borders). Otherwise, it should be assumed that the data is random, and
    // that it may overlap. The writer should then either throw an error or
    // start buffering data manually.
    //
    // @param width image width
    // @param height image height
    // @param tileSize tile size or 0 if the image will not be sent in tiled
    // form
    // @throws IOException thrown if an I/O error occurs
    // @throws UnsupportedOperationException thrown if this writer does not
    // support writing the image with the supplied tile size
    func writeHeader(_ width: Int32, _ height: Int32, _ tileSize: Int32) throws

    // Write a tile of data. Note that this method may be called by more than
    // one thread, so it should be made thread-safe if possible.
    //
    // @param x tile x coordinate
    // @param y tile y coordinate
    // @param w tile width
    // @param h tile height
    // @param color color data
    // @param alpha alpha data
    // @throws IOException thrown if an I/O error occurs
    func writeTile(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ color: [Color], _ alpha: [Float]) throws

    // Close the file, this completes the bitmap writing process.
    //
    // @throws IOException thrown if an I/O error occurs
    func closeFile() throws
}
