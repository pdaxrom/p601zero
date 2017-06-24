; Boot sector
			section 0
			ds	3	; _a
_name			ds	8
_bytes_per_sector	ds	2
_sectors_per_cluster	ds	1
_reserved_sectors	ds	2
_fats			ds	1
_root_entries		ds	2
_total_sectors		ds	2
_media_descriptor	ds	1
_sectors_per_fat	ds	2
_sectors_per_track	ds	2
_heads			ds	2
_hidden_sectors		ds	4
_total_sectors2		ds	4
_drive_index		ds	1
			ds	1	; _b
_signature		ds	1
_id			ds	4
_label			ds	11
_type			ds	8
			ds	448	; _c
_sig			ds	2
			ends

; Root directory entry
			section 0
_filename		ds	8
_extension		ds	3
_attributes		ds	1
			ds	1	; _a
_create_time_us		ds	1
_create_time		ds	2
_create_date		ds	2
_last_access_date	ds	2
			ds	2	; _b
_last_mod_time		ds	2
_last_mod_date		ds	2
_cluster		ds	2
_size			ds	4
			ends
