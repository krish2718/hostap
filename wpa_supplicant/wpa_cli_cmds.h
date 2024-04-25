enum wpa_cli_cmd_flags {
	cli_cmd_flag_none		= 0x00,
	cli_cmd_flag_sensitive		= 0x01
};

struct wpa_cli_cmd {
	const char *cmd;
	int (*handler)(struct wpa_ctrl *ctrl, int argc, char *argv[]);
	char ** (*completion)(const char *str, int pos);
	enum wpa_cli_cmd_flags flags;
	const char *usage;
};

extern const struct wpa_cli_cmd wpa_cli_commands[];
extern const size_t wpa_cli_commands_size;


extern struct dl_list bsses; /* struct cli_txt_entry */
extern struct dl_list p2p_peers; /* struct cli_txt_entry */
extern struct dl_list p2p_groups; /* struct cli_txt_entry */
extern struct dl_list ifnames; /* struct cli_txt_entry */
extern struct dl_list networks; /* struct cli_txt_entry */
extern struct dl_list creds; /* struct cli_txt_entry */
 #ifdef CONFIG_AP
extern struct dl_list stations; /* struct cli_txt_entry */
 #endif /* CONFIG_AP */