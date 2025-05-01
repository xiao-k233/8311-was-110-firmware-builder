#!/bin/bash

# 加载通用函数
[ -f "mods/common-functions.sh" ] && . mods/common-functions.sh

_mod_info "Starting binary modifications..."

OMCID="$ROOT_DIR/opt/intel/bin/omcid"
# Azores 1.0.12
if check_file "$OMCID" "0aa64358a3afaa17b4edfed0077141981bc13322c7d1cf730abc251fae1ecbb1"; then
	echo "Patching '$OMCID'..."
	_mod_info "Original hash: 0aa64358a3afaa17b4edfed0077141981bc13322c7d1cf730abc251fae1ecbb1"

	# omcid mod by djGrrr to make default LOID and LPWD empty
	binary_patch "$OMCID" $((0xF42F4)) '\x00\x00\x00\x00\x00\x00' "Make default LOID empty"
	binary_patch "$OMCID" $((0xF4304)) '\x00\x00\x00\x00\x00\x00\x00\x00\x00' "Make default LPWD empty"

	expected_hash "$OMCID" "cb4c3e631ea783aebf8603298da0b7a2ac0c3750a2d35be0c5f80a93e64228ec"
	_mod_info "Final hash: cb4c3e631ea783aebf8603298da0b7a2ac0c3750a2d35be0c5f80a93e64228ec"
fi

# Azores 1.0.19
if check_file "$OMCID" "d696843c3801cb68f9d779ed95bd72299fcb2fa05459c17bac5d346645562067"; then
	echo "Patching '$OMCID'..."
	_mod_info "Original hash: d696843c3801cb68f9d779ed95bd72299fcb2fa05459c17bac5d346645562067"

	# omcid mod by djGrrr to make default LOID and LPWD empty
	binary_patch "$OMCID" $((0xF43F4)) '\x00\x00\x00\x00\x00\x00' "Make default LOID empty"
	binary_patch "$OMCID" $((0xF4404)) '\x00\x00\x00\x00\x00\x00\x00\x00\x00' "Make default LPWD empty"

	expected_hash "$OMCID" "0111a39c55f776e9b9756833943a06a19bffe973e601e8a1abb1dfab3647f733"
	_mod_info "Final hash: 0111a39c55f776e9b9756833943a06a19bffe973e601e8a1abb1dfab3647f733"
fi


OMCID="$ROOT_DIR/usr/bin/omcid"
# Potrontec 1.18.1 OMCId v8.15.17
if check_file "$OMCID" "82b6746d5385d676765d185a21443fabcab63f193fac7eb56a1a8cd878f029d5"; then
	echo "Patching '$OMCID'..."
	_mod_info "Original hash: 82b6746d5385d676765d185a21443fabcab63f193fac7eb56a1a8cd878f029d5"

	# omcid mod by djGrrr to make default LOID and LPWD empty
	binary_patch "$OMCID" $((0x9FBF8)) '\x00\x00\x00\x00\x00\x00' "Make default LOID empty"
	binary_patch "$OMCID" $((0x9FC08)) '\x00\x00\x00\x00\x00\x00\x00\x00\x00' "Make default LPWD empty"

	expected_hash "$OMCID" "184aad016a0d38da5c3a6fc8451f8b4971be59702d6d10a2bca379b2f9bce7f7"
	_mod_info "Final hash: 184aad016a0d38da5c3a6fc8451f8b4971be59702d6d10a2bca379b2f9bce7f7"
fi

# PTXG_CX_V0.03
if check_file "$OMCID" "5217dccf98cf8c75bc1b8ba380a92514511a77c40803a9718651b1f2bb5a9a5a"; then
	echo "Patching '$OMCID'..."
	_mod_info "Original hash: 5217dccf98cf8c75bc1b8ba380a92514511a77c40803a9718651b1f2bb5a9a5a"

	# omcid mod by djGrrr to make default LOID and LPWD empty
	binary_patch "$OMCID" $((0xA04C8)) '\x00\x00\x00\x00\x00\x00' "Make default LOID empty"
	binary_patch "$OMCID" $((0xA04D8)) '\x00\x00\x00\x00\x00\x00\x00\x00\x00' "Make default LPWD empty"

	# omci_sip_user_data.c - ME 153 function sip_user_update_timeout_handler - fix data length when reading ME 148 attribute username2
	binary_patch "$OMCID" $((0x80C77)) '\x19' "Fix data length for ME 148 attribute username2"

	# omci_sip_agent_config_data.c - ME 150 function me_update - fix data lengths when reading ME 136 and 134 attributes
	binary_patch "$OMCID" $((0x82403)) '\x02' "Fix data length for ME 136/134 attributes (1)"
	binary_patch "$OMCID" $((0x825C7)) '\x3C' "Fix data length for ME 136/134 attributes (2)"
	binary_patch "$OMCID" $((0x825CB)) '\x04' "Fix data length for ME 136/134 attributes (3)"
	binary_patch "$OMCID" $((0x825F1)) '\x16' "Fix data length for ME 136/134 attributes (4)"
	binary_patch "$OMCID" $((0x825F5)) '\xB6' "Fix data length for ME 136/134 attributes (5)"
	binary_patch "$OMCID" $((0x82624)) '\xAF\xB6\x00\x10\x24\x16\x00\x04' "Fix data length for ME 136/134 attributes (6)"
	binary_patch "$OMCID" $((0x8262F)) '\x6C' "Fix data length for ME 136/134 attributes (7)"
	binary_patch "$OMCID" $((0x82633)) '\x02' "Fix data length for ME 136/134 attributes (8)"

	expected_hash "$OMCID" "c1df5decc2aa80a583abf0d8b1a237cc603ceeabd4acee4f7e8bbb6a91fd6848"
	_mod_info "Final hash: c1df5decc2aa80a583abf0d8b1a237cc603ceeabd4acee4f7e8bbb6a91fd6848"
fi

# Potrontec 1.18.1 OMCId v8.15.17 and PTXG_CX_V0.03
LIBPON="$ROOT_DIR/usr/lib/libpon.so.0.0.0"
if check_file "$LIBPON" "401cc97e0f43b6b08a1d27f7be94a9e37fa798a810ae89838776f14b55e66cc1"; then
	echo "Patching '$LIBPON'..."
	_mod_info "Original hash: 401cc97e0f43b6b08a1d27f7be94a9e37fa798a810ae89838776f14b55e66cc1"

	# NOP system() calls to sfp_i2c
	binary_patch "$LIBPON" $((0x17850)) '\x00\x00\x00\x00' "NOP system() call to sfp_i2c (1)"
	binary_patch "$LIBPON" $((0x17894)) '\x00\x00\x00\x00' "NOP system() call to sfp_i2c (2)"
	binary_patch "$LIBPON" $((0x178BC)) '\x00\x00\x00\x00' "NOP system() call to sfp_i2c (3)"
	binary_patch "$LIBPON" $((0x17940)) '\x00\x00\x00\x00' "NOP system() call to sfp_i2c (4)"
	binary_patch "$LIBPON" $((0x179D8)) '\x00\x00\x00\x00' "NOP system() call to sfp_i2c (5)"
	binary_patch "$LIBPON" $((0x17A08)) '\x00\x00\x00\x00' "NOP system() call to sfp_i2c (6)"

	expected_hash "$LIBPON" "b9deb9b22715a4c4f54307939d94ac7b15e116aa5f5edabea5ba7365d3b807dc"
	_mod_info "Final hash: b9deb9b22715a4c4f54307939d94ac7b15e116aa5f5edabea5ba7365d3b807dc"
fi

# libponnet mod for 1.0.12 to fix management with VEIP mode
LIBPONNET="$ROOT_DIR/usr/lib/libponnet.so.0.0.0"
if check_file "$LIBPONNET" "8075079231811f58dd4cec06ed84ff5d46a06e40b94c14263a56110edfa2a705"; then
	echo "Patching '$LIBPONNET'..."
	_mod_info "Original hash: 8075079231811f58dd4cec06ed84ff5d46a06e40b94c14263a56110edfa2a705"

	# patch pon_net_dev_db_add to return 0 instead of -1 when an existing device entry exists
	binary_patch "$LIBPONNET" $((0x51B9A)) '\x00\x00' "Return 0 instead of -1 for existing device"

	# patch file location for IP Host hostname
	binary_patch "$LIBPONNET" $((0x92064)) '/tmp/8311-iphost-hostname\x00' "Change IP Host hostname file location"

	# patch file location for IP Host domain
	binary_patch "$LIBPONNET" $((0x92090)) '/tmp/8311-iphost-domainname\x00' "Change IP Host domain file location"

	expected_hash "$LIBPONNET" "1d92a9cf288f64317f6d82e8f87651fbc07bef53ce3f4f28e73fc17e6041b107"
	_mod_info "Final hash: 1d92a9cf288f64317f6d82e8f87651fbc07bef53ce3f4f28e73fc17e6041b107"
fi

# libponnet mod for 1.0.19 to fix management with VEIP mode
if check_file "$LIBPONNET" "f1031d3452f86647dbdf4b6c94abaccdc05b9d3b2c339bf560db0191e799f0c6"; then
	echo "Patching '$LIBPONNET'..."
	_mod_info "Original hash: f1031d3452f86647dbdf4b6c94abaccdc05b9d3b2c339bf560db0191e799f0c6"

	# patch pon_net_dev_db_add to return 0 instead of -1 when an existing device entry exists
	binary_patch "$LIBPONNET" $((0x51B9A)) '\x00\x00' "Return 0 instead of -1 for existing device"

	# patch file location for IP Host hostnam
	binary_patch "$LIBPONNET" $((0x92084)) '/tmp/8311-iphost-hostname\x00' "Change IP Host hostname file location"

	# patch file location for IP Host domain
	binary_patch "$LIBPONNET" $((0x920B0)) '/tmp/8311-iphost-domainname\x00' "Change IP Host domain file location"

	expected_hash "$LIBPONNET" "baa8d1dc984387aaec12afe8f24338b19b8b162430ebea11d670c924c09cad00"
	_mod_info "Final hash: baa8d1dc984387aaec12afe8f24338b19b8b162430ebea11d670c924c09cad00"
fi

# Potrontec 1.18.1 OMCId v8.15.17
if check_file "$LIBPONNET" "05536d164e51c5d412421a347a5c99b6883a53c57c24ed4d00f4b98b79cddfc3"; then
	echo "Patching '$LIBPONNET'..."
	_mod_info "Original hash: 05536d164e51c5d412421a347a5c99b6883a53c57c24ed4d00f4b98b79cddfc3"

	# patch pon_net_dev_db_add to return 0 instead of -1 when an existing device entry exists, fixes VEIP management
	binary_patch "$LIBPONNET" $((0x3CDC2)) '\x00\x00' "Return 0 instead of -1 for existing device"

	# patch file location for IP Host hostname
	binary_patch "$LIBPONNET" $((0x6BC40)) '/tmp/8311-iphost-hostname\x00' "Change IP Host hostname file location"

	# patch file location for IP Host domain
	binary_patch "$LIBPONNET" $((0x6BC0C)) '/tmp/8311-iphost-domainname\x00' "Change IP Host domain file location"

	expected_hash "$LIBPONNET" "71e5fa85bde3793cdc1085781e3a1440fc9ef0bb8900c74d144b99be720ba50e"
	_mod_info "Final hash: 71e5fa85bde3793cdc1085781e3a1440fc9ef0bb8900c74d144b99be720ba50e"
fi

# PTXG_CX_V0.03
if check_file "$LIBPONNET" "ac12631273e8cf069aecbba55e02ace987d54ddf70bc0e14211dabf4abc600b7"; then
	echo "Patching '$LIBPONNET'..."
	_mod_info "Original hash: ac12631273e8cf069aecbba55e02ace987d54ddf70bc0e14211dabf4abc600b7"

	# patch pon_net_dev_db_add to return 0 instead of -1 when an existing device entry exists, fixes VEIP management
	binary_patch "$LIBPONNET" $((0x3D1D2)) '\x00\x00' "Return 0 instead of -1 for existing device"

	# patch file location for IP Host hostname
	binary_patch "$LIBPONNET" $((0x6C050)) '/tmp/8311-iphost-hostname\x00' "Change IP Host hostname file location"

	# patch file location for IP Host domain
	binary_patch "$LIBPONNET" $((0x6C01C)) '/tmp/8311-iphost-domainname\x00' "Change IP Host domain file location"

	expected_hash "$LIBPONNET" "687f88bda014c86e7c6bff59857d10ea3bfe7307d6204bc327c616e8b39b20bc"
	_mod_info "Final hash: 687f88bda014c86e7c6bff59857d10ea3bfe7307d6204bc327c616e8b39b20bc"
fi

LIBPONHWAL="$ROOT_DIR/ptrom/lib/libponhwal.so"
# libponhwal mods for 1.0.12 to fix Software/Hardware versions and Equipment ID
if check_file "$LIBPONHWAL" "f0e48ceba56c7d588b8bcd206c7a3a66c5c926fd1d69e6d9d5354bf1d34fdaf6"; then
	echo "Patching '$LIBPONHWAL'..."
	_mod_info "Original hash: f0e48ceba56c7d588b8bcd206c7a3a66c5c926fd1d69e6d9d5354bf1d34fdaf6"

	# patch ponhw_get_hardware_ver to use the correct string length (by rajkosto)
	binary_patch "$LIBPONHWAL" $((0x278CB)) '\x0E' "Fix hardware version string length"

	# patch ponhw_get_software_ver to use the correct string length (by rajkosto)
	binary_patch "$LIBPONHWAL" $((0x277C7)) '\x0E' "Fix software version string length (1)"
	binary_patch "$LIBPONHWAL" $((0x27823)) '\x0E' "Fix software version string length (2)"

	# patch ponhw_get_equipment_id to use the correct string length (by djGrrr)
	binary_patch "$LIBPONHWAL" $((0x27647)) '\x14' "Fix equipment ID string length"

	expected_hash "$LIBPONHWAL" "624aa5875a7bcf4d91a060e076475336622b267ff14b9c8fbb87df30fc889788"
	_mod_info "Final hash: 624aa5875a7bcf4d91a060e076475336622b267ff14b9c8fbb87df30fc889788"
fi

# libponhwal mods for 1.0.19 to fix Software/Hardware versions and Equipment ID
if check_file "$LIBPONHWAL" "cd157969cd9127d97709a96f3612f6f7c8f0eff05d4586fde178e9c4b7a4d362"; then
	echo "Patching '$LIBPONHWAL'..."
	_mod_info "Original hash: cd157969cd9127d97709a96f3612f6f7c8f0eff05d4586fde178e9c4b7a4d362"

	# patch ponhw_get_hardware_ver to use the correct string length (by djGrrr, based on rajkosto's patch for 1.0.12)
	binary_patch "$LIBPONHWAL" $((0x278A3)) '\x0E' "Fix hardware version string length"

	# patch ponhw_get_software_ver to use the correct string length (by djGrrr, based on rajkosto's patch for 1.0.12)
	binary_patch "$LIBPONHWAL" $((0x2779F)) '\x0E' "Fix software version string length (1)"
	binary_patch "$LIBPONHWAL" $((0x277FB)) '\x0E' "Fix software version string length (2)"

	# patch ponhw_get_equipment_id to use the correct string length (by djGrrr)
	binary_patch "$LIBPONHWAL" $((0x2C2B7)) '\x14' "Fix equipment ID string length"

	expected_hash "$LIBPONHWAL" "48f932b62fd22c693bae0aa99962a4821ef18f503eed3822d41d44330cb32db5"
	_mod_info "Final hash: 48f932b62fd22c693bae0aa99962a4821ef18f503eed3822d41d44330cb32db5"
fi

# libponhwal mods for 1.0.8 to fix Software/Hardware versions and Equipment ID
if check_file "$LIBPONHWAL" "6af1b3b1fba25488fd68e5e2e2c41ab0e178bd190f0ba2617fc32bdfad21e4c4"; then
	echo "Patching '$LIBPONHWAL'..."
	_mod_info "Original hash: 6af1b3b1fba25488fd68e5e2e2c41ab0e178bd190f0ba2617fc32bdfad21e4c4"

	# patch ponhw_get_hardware_ver to use the correct string length ((by djGrrr, based on rajkosto's patch for 1.0.12)
	binary_patch "$LIBPONHWAL" $((0x2738B)) '\x0E' "Fix hardware version string length"

	# patch ponhw_get_software_ver to use the correct string length (by djGrrr, based on rajkosto's patch for 1.0.12)
	binary_patch "$LIBPONHWAL" $((0x27287)) '\x0E' "Fix software version string length (1)"
	binary_patch "$LIBPONHWAL" $((0x272E3)) '\x0E' "Fix software version string length (2)"

	# patch ponhw_get_equipment_id to use the correct string length (by djGrrr)
	binary_patch "$LIBPONHWAL" $((0x27107)) '\x14' "Fix equipment ID string length"

	expected_hash "$LIBPONHWAL" "36b20ed9c64de010e14543659302fdb85090efc49e48c193c2c156f6333afaac"
	_mod_info "Final hash: 36b20ed9c64de010e14543659302fdb85090efc49e48c193c2c156f6333afaac"
fi

_mod_info "Binary modifications completed"
