compile:
	jai example.jai -import_dir ../oleg/modules -output_path output/

run:
	jai example.jai -import_dir ../oleg/modules -output_path output/ && output/example
