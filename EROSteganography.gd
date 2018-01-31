# ERO-ONE's Steganography Library

extends Node

const STEGANO_MAGIC_NUMBER = [0x45, 0x52, 0x4f, 0x31] #ERO1
const STEGANO_CHUNK_END = [0x45, 0x52, 0x4f, 0x45] #EROE
const BITS_PER_BYTE = 2 # How many bits we take from each one, 1 is the least singificant bit
const STEGANO_FORMAT_VERSION = 1
const DATA_OFFSET = 0 # Offset for where the data starts in the image

func store_string_in_image(image, string):
	var payload = PoolByteArray(STEGANO_MAGIC_NUMBER)
	
	var text_binary = string.to_utf8()
	var text_compressed = text_binary.compress(File.COMPRESSION_ZSTD)
	
	# split the int into four bytes
	var uncompressed_data_size = PoolByteArray([0x00,0x00,0x00,0x00])
	uncompressed_data_size[3] = text_binary.size()
	uncompressed_data_size[2] = text_binary.size() >> 8
	uncompressed_data_size[1] = text_binary.size() >> 16
	uncompressed_data_size[0] = text_binary.size() >> 24
	
	payload.append(STEGANO_FORMAT_VERSION)
	payload.append_array(uncompressed_data_size)
	payload.append_array(text_compressed)
	payload.append_array(PoolByteArray(STEGANO_CHUNK_END))
	
	return store_data_in_image(image, payload)

# Data should be a PoolByteArray
func store_data_in_image(image, data):
	image.convert(Image.FORMAT_RGB8)
	var image_data = image.get_data()
	var writing_mask = 0
	for mask_i in range(BITS_PER_BYTE):
		writing_mask = writing_mask | (0x1 << mask_i)
	var image_position = 0
	for byte_i in range(data.size()):
		var images_bytes_per_byte = 8/BITS_PER_BYTE
		for insert_i in range(images_bytes_per_byte):
			var insertion_mask = writing_mask << insert_i * BITS_PER_BYTE
			var bits_to_write = data[byte_i] & insertion_mask
			bits_to_write = bits_to_write >> insert_i*BITS_PER_BYTE
			var image_data_mask = 0xFF >> BITS_PER_BYTE
			image_data_mask = image_data_mask << BITS_PER_BYTE
			image_data[image_position+insert_i] = image_data[image_position+insert_i] & image_data_mask
			image_data[image_position+insert_i] = image_data[image_position+insert_i] | bits_to_write
		image_position += images_bytes_per_byte
	var final_image = Image.new()
	final_image.create_from_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGB8, image_data)
	return final_image
	
func get_steganographic_data_from_image(image):
	image.convert(Image.FORMAT_RGB8)
	var extracted_data = PoolByteArray()
	var image_data = image.get_data()

	var data_mask = 0
	for mask_i in range(BITS_PER_BYTE):
		data_mask = data_mask | (0x1 << mask_i)
	var current_byte = 0
	
	var magic_number_position = -1
	
	for byte_i in range(image_data.size()):
		var data = image_data[byte_i] & data_mask
		var iterations_per_byte = 8/BITS_PER_BYTE
		var current_bits = data & data_mask
		current_byte = current_byte | (current_bits << ((byte_i % iterations_per_byte)*BITS_PER_BYTE))
		# For every 8 bits we parse, save the current byte
		if byte_i % iterations_per_byte == iterations_per_byte-1:
			extracted_data.append(current_byte)
			if byte_i < 64:
				pass
			current_byte = 0
			
			# Magic number check
			var magic_number = PoolByteArray(STEGANO_MAGIC_NUMBER)
			if extracted_data.size() == DATA_OFFSET + magic_number.size():
				var potential_magic_number = extracted_data.subarray(extracted_data.size()-PoolByteArray(STEGANO_MAGIC_NUMBER).size(), extracted_data.size()-1)
				if potential_magic_number == PoolByteArray(STEGANO_MAGIC_NUMBER):
					magic_number_position = extracted_data.size()-1
				else:
					return ERR_FILE_CORRUPT
			
			# Try and find the ending marker (EROE)
			if extracted_data.size() >= DATA_OFFSET + magic_number.size():
				var potential_chunk_end = extracted_data.subarray(extracted_data.size()-PoolByteArray(STEGANO_CHUNK_END).size(), extracted_data.size()-1)
				if potential_chunk_end == PoolByteArray(STEGANO_CHUNK_END):
					break
		
	# data decoding
	if magic_number_position != -1:
		
		var version_number = extracted_data[magic_number_position+1]
		
		# Reconstruct the uncompressed size int
		var uncompressed_size_bytes = extracted_data.subarray(magic_number_position+2, magic_number_position+5)
		var uncompressed_size = uncompressed_size_bytes[3]
		uncompressed_size = uncompressed_size | uncompressed_size_bytes[2] << 8
		uncompressed_size = uncompressed_size | uncompressed_size_bytes[1] << 16
		uncompressed_size = uncompressed_size | uncompressed_size_bytes[0] << 24
		
		# Get all remainin data except EROE
		var compressed_data = extracted_data.subarray(magic_number_position+6, extracted_data.size()-1-STEGANO_CHUNK_END.size())
		
		var uncompressed_data = compressed_data.decompress(uncompressed_size, File.COMPRESSION_ZSTD).get_string_from_utf8()
		print(uncompressed_size)
		return uncompressed_data
	else:
		return ERR_FILE_CORRUPT
		
func get_steganographic_data_from_file(image_path):
	var file = File.new()
	if file.file_exists(image_path):
		var image = Image.new()
		image.load(image_path)
		var result = get_steganographic_data_from_image(image)
		return result
	else:
		return ERR_FILE_NOT_FOUND
	