![alt text](docs/images/logo2.png)

This is the code used by the [ERO-ONE](https://ero-one.moe) erotic game for loading and saving character data to png files (known as character cards).

# Constants
STEGANO_MAGIC_NUMBER: Set of bytes used to indicate where your stored files start (in the case of ERO-ONE it's ERO1)

STEGANO_CHUNK_END: Set of bytes used to indicate where your stored files end (in the case of ERO-ONE it's EROE)

BITS_PER_BYTE: How many least significant bytes we should use, ERO-ONE uses 2

DATA_OFFSET: Don't touch, the data offset functionality isn't done yet.

ERO-ONE's character storage binary data spec:

| Position | Name | Description |
|--|--|--|
| 0x0 - 0x03 | Start marker (ERO1) | Marks where the character file starts |
| 0x4 | File version | Character file format version (currently 1) |
| 0x5-0x8 | Length of the uncompressed data information | Contains the size in bytes of the json file before being compressed (it's a 32 bit integer) |
| 0x9 - ? | Compressed data | Contains the compressed json file |
| ? - ? | Ending marker (EROE) | Marks the end of the file |
