# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_screenpipe_global_optspecs
	string join \n f/fps= d/audio-chunk-duration= p/port= disable-audio i/audio-device= r/realtime-audio-device= data-dir= debug a/audio-transcription-engine= enable-realtime-audio-transcription enable-realtime-vision o/ocr-engine= m/monitor-id= l/language= use-pii-removal disable-vision vad-engine= ignored-windows= included-windows= video-chunk-duration= deepgram-api-key= auto-destruct-pid= vad-sensitivity= disable-telemetry enable-llm enable-ui-monitoring enable-frame-cache capture-unfocused-windows h/help V/version
end

function __fish_screenpipe_needs_command
	# Figure out if the current invocation already has a command.
	set -l cmd (commandline -opc)
	set -e cmd[1]
	argparse -s (__fish_screenpipe_global_optspecs) -- $cmd 2>/dev/null
	or return
	if set -q argv[1]
		# Also print the command, so this can be used to figure out what it is.
		echo $argv[1]
		return 1
	end
	return 0
end

function __fish_screenpipe_using_subcommand
	set -l cmd (__fish_screenpipe_needs_command)
	test -z "$cmd"
	and return 1
	contains -- $cmd[1] $argv
end

complete -c screenpipe -n "__fish_screenpipe_needs_command" -s f -l fps -d 'FPS for continuous recording 1 FPS = 30 GB / month 5 FPS = 150 GB / month Optimise based on your needs. Your screen rarely change more than 1 times within a second, right?' -r
complete -c screenpipe -n "__fish_screenpipe_needs_command" -s d -l audio-chunk-duration -d 'Audio chunk duration in seconds' -r
complete -c screenpipe -n "__fish_screenpipe_needs_command" -s p -l port -d 'Port to run the server on' -r
complete -c screenpipe -n "__fish_screenpipe_needs_command" -s i -l audio-device -d 'Audio devices to use (can be specified multiple times)' -r
complete -c screenpipe -n "__fish_screenpipe_needs_command" -s r -l realtime-audio-device -r
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l data-dir -d 'Data directory. Default to $HOME/.screenpipe' -r -f -a "(__fish_complete_directories)"
complete -c screenpipe -n "__fish_screenpipe_needs_command" -s a -l audio-transcription-engine -d 'Audio transcription engine to use. Deepgram is a very high quality cloud-based transcription service (free of charge on us for now), recommended for high quality audio. WhisperTiny is a local, lightweight transcription model, recommended for high data privacy. WhisperDistilLargeV3 is a local, lightweight transcription model (-a whisper-large), recommended for higher quality audio than tiny. WhisperLargeV3Turbo is a local, lightweight transcription model (-a whisper-large-v3-turbo), recommended for higher quality audio than tiny' -r -f -a "deepgram\t''
whisper-tiny\t''
whisper-tiny-quantized\t''
whisper-large\t''
whisper-large-quantized\t''
whisper-large-v3-turbo\t''
whisper-large-v3-turbo-quantized\t''"
complete -c screenpipe -n "__fish_screenpipe_needs_command" -s o -l ocr-engine -d 'OCR engine to use. AppleNative is the default local OCR engine for macOS. WindowsNative is a local OCR engine for Windows. Unstructured is a cloud OCR engine (free of charge on us for now), recommended for high quality OCR. Tesseract is a local OCR engine (not supported on macOS)' -r -f -a "unstructured\t''
apple-native\t''
custom\t''"
complete -c screenpipe -n "__fish_screenpipe_needs_command" -s m -l monitor-id -d 'Monitor IDs to use, these will be used to select the monitors to record' -r
complete -c screenpipe -n "__fish_screenpipe_needs_command" -s l -l language -r -f -a "english\t''
chinese\t''
german\t''
spanish\t''
russian\t''
korean\t''
french\t''
japanese\t''
portuguese\t''
turkish\t''
polish\t''
catalan\t''
dutch\t''
arabic\t''
swedish\t''
italian\t''
indonesian\t''
hindi\t''
finnish\t''
hebrew\t''
ukrainian\t''
greek\t''
malay\t''
czech\t''
romanian\t''
danish\t''
hungarian\t''
norwegian\t''
thai\t''
urdu\t''
croatian\t''
bulgarian\t''
lithuanian\t''
latin\t''
malayalam\t''
welsh\t''
slovak\t''
persian\t''
latvian\t''
bengali\t''
serbian\t''
azerbaijani\t''
slovenian\t''
estonian\t''
macedonian\t''
nepali\t''
mongolian\t''
bosnian\t''
kazakh\t''
albanian\t''
swahili\t''
galician\t''
marathi\t''
punjabi\t''
sinhala\t''
khmer\t''
afrikaans\t''
belarusian\t''
gujarati\t''
amharic\t''
yiddish\t''
lao\t''
uzbek\t''
faroese\t''
pashto\t''
maltese\t''
sanskrit\t''
luxembourgish\t''
myanmar\t''
tibetan\t''
tagalog\t''
assamese\t''
tatar\t''
hausa\t''
javanese\t''"
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l vad-engine -d 'VAD engine to use for speech detection' -r -f -a "webrtc\t''
silero\t''"
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l ignored-windows -d 'List of windows to ignore (by title) for screen recording - we use contains to match, example: --ignored-windows "Spotify" --ignored-windows "Bit" will ignore both "Bitwarden" and "Bittorrent" --ignored-windows "x" will ignore "Home / X" and "SpaceX"' -r
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l included-windows -d 'List of windows to include (by title) for screen recording - we use contains to match, example: --included-windows "Chrome" will include "Google Chrome" --included-windows "WhatsApp" will include "WhatsApp"' -r
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l video-chunk-duration -d 'Video chunk duration in seconds' -r
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l deepgram-api-key -d 'Deepgram API Key for audio transcription' -r
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l auto-destruct-pid -d 'PID to watch for auto-destruction. If provided, screenpipe will stop when this PID is no longer running' -r
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l vad-sensitivity -d 'Voice activity detection sensitivity level' -r -f -a "low\t''
medium\t''
high\t''"
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l disable-audio -d 'Disable audio recording'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l debug -d 'Enable debug logging for screenpipe modules'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l enable-realtime-audio-transcription -d 'Enable realtime audio transcription'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l enable-realtime-vision -d 'Enable realtime vision'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l use-pii-removal -d 'Enable PII removal from OCR text property that is saved to db and returned in search results'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l disable-vision -d 'Disable vision recording'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l disable-telemetry -d 'Disable telemetry'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l enable-llm -d 'Enable Local LLM API'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l enable-ui-monitoring -d 'Enable UI monitoring (macOS only)'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l enable-frame-cache -d 'Enable experimental video frame cache (may increase CPU usage) - makes timeline UI available, frame streaming, etc'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -l capture-unfocused-windows -d 'Capture windows that are not focused (default: false)'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -s V -l version -d 'Print version'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -f -a "audio" -d 'Audio device management commands'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -f -a "vision" -d 'Vision device management commands'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -f -a "pipe" -d 'Pipe management commands'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -f -a "mcp" -d 'MCP Server management commands'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -f -a "add" -d 'Add video files to existing screenpipe data (OCR only) - DOES NOT SUPPORT AUDIO'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -f -a "migrate" -d 'Run data migrations in the background'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -f -a "completions" -d 'Generate shell completions'
complete -c screenpipe -n "__fish_screenpipe_needs_command" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand audio; and not __fish_seen_subcommand_from list help" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand audio; and not __fish_seen_subcommand_from list help" -f -a "list" -d 'List available audio devices'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand audio; and not __fish_seen_subcommand_from list help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand audio; and __fish_seen_subcommand_from list" -s o -l output -d 'Output format' -r -f -a "text\t''
json\t''"
complete -c screenpipe -n "__fish_screenpipe_using_subcommand audio; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand audio; and __fish_seen_subcommand_from help" -f -a "list" -d 'List available audio devices'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand audio; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand vision; and not __fish_seen_subcommand_from list help" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand vision; and not __fish_seen_subcommand_from list help" -f -a "list" -d 'List available monitors and vision devices'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand vision; and not __fish_seen_subcommand_from list help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand vision; and __fish_seen_subcommand_from list" -s o -l output -d 'Output format' -r -f -a "text\t''
json\t''"
complete -c screenpipe -n "__fish_screenpipe_using_subcommand vision; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand vision; and __fish_seen_subcommand_from help" -f -a "list" -d 'List available monitors and vision devices'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand vision; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and not __fish_seen_subcommand_from list download install info enable disable update purge delete help" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and not __fish_seen_subcommand_from list download install info enable disable update purge delete help" -f -a "list" -d 'List all pipes'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and not __fish_seen_subcommand_from list download install info enable disable update purge delete help" -f -a "download" -d 'Download a new pipe (deprecated: use \'install\' instead)'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and not __fish_seen_subcommand_from list download install info enable disable update purge delete help" -f -a "install" -d 'Install a new pipe'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and not __fish_seen_subcommand_from list download install info enable disable update purge delete help" -f -a "info" -d 'Get info for a specific pipe'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and not __fish_seen_subcommand_from list download install info enable disable update purge delete help" -f -a "enable" -d 'Enable a pipe'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and not __fish_seen_subcommand_from list download install info enable disable update purge delete help" -f -a "disable" -d 'Disable a pipe'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and not __fish_seen_subcommand_from list download install info enable disable update purge delete help" -f -a "update" -d 'Update pipe configuration'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and not __fish_seen_subcommand_from list download install info enable disable update purge delete help" -f -a "purge" -d 'Purge all pipes'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and not __fish_seen_subcommand_from list download install info enable disable update purge delete help" -f -a "delete" -d 'Delete a pipe'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and not __fish_seen_subcommand_from list download install info enable disable update purge delete help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from list" -s o -l output -d 'Output format' -r -f -a "text\t''
json\t''"
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from list" -s p -l port -d 'Server port' -r
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from download" -s o -l output -d 'Output format' -r -f -a "text\t''
json\t''"
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from download" -s p -l port -d 'Server port' -r
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from download" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from install" -s o -l output -d 'Output format' -r -f -a "text\t''
json\t''"
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from install" -s p -l port -d 'Server port' -r
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from install" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from info" -s o -l output -d 'Output format' -r -f -a "text\t''
json\t''"
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from info" -s p -l port -d 'Server port' -r
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from info" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from enable" -s p -l port -d 'Server port' -r
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from enable" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from disable" -s p -l port -d 'Server port' -r
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from disable" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from update" -s p -l port -d 'Server port' -r
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from update" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from purge" -s p -l port -d 'Server port' -r
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from purge" -s y -l yes -d 'Automatically confirm purge without prompting'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from purge" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from delete" -s p -l port -d 'Server port' -r
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from delete" -s y -l yes -d 'Automatically confirm deletion without prompting'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from help" -f -a "list" -d 'List all pipes'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from help" -f -a "download" -d 'Download a new pipe (deprecated: use \'install\' instead)'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from help" -f -a "install" -d 'Install a new pipe'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from help" -f -a "info" -d 'Get info for a specific pipe'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from help" -f -a "enable" -d 'Enable a pipe'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from help" -f -a "disable" -d 'Disable a pipe'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from help" -f -a "update" -d 'Update pipe configuration'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from help" -f -a "purge" -d 'Purge all pipes'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete a pipe'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand pipe; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand mcp; and not __fish_seen_subcommand_from setup help" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand mcp; and not __fish_seen_subcommand_from setup help" -f -a "setup" -d 'Setup MCP server configuration'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand mcp; and not __fish_seen_subcommand_from setup help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand mcp; and __fish_seen_subcommand_from setup" -l directory -d 'Directory to save MCP files (default: $HOME/.screenpipe/mcp)' -r -f -a "(__fish_complete_directories)"
complete -c screenpipe -n "__fish_screenpipe_using_subcommand mcp; and __fish_seen_subcommand_from setup" -s o -l output -d 'Output format' -r -f -a "text\t''
json\t''"
complete -c screenpipe -n "__fish_screenpipe_using_subcommand mcp; and __fish_seen_subcommand_from setup" -s p -l port -d 'Server port' -r
complete -c screenpipe -n "__fish_screenpipe_using_subcommand mcp; and __fish_seen_subcommand_from setup" -l update -d 'Force update existing files'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand mcp; and __fish_seen_subcommand_from setup" -l purge -d 'Purge existing MCP directory before setup'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand mcp; and __fish_seen_subcommand_from setup" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand mcp; and __fish_seen_subcommand_from help" -f -a "setup" -d 'Setup MCP server configuration'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand mcp; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand add" -l data-dir -d 'Data directory. Default to $HOME/.screenpipe' -r -f -a "(__fish_complete_directories)"
complete -c screenpipe -n "__fish_screenpipe_using_subcommand add" -s o -l output -d 'Output format' -r -f -a "text\t''
json\t''"
complete -c screenpipe -n "__fish_screenpipe_using_subcommand add" -l pattern -d 'Regex pattern to filter files (e.g. "monitor.*\\.mp4$")' -r
complete -c screenpipe -n "__fish_screenpipe_using_subcommand add" -s o -l ocr-engine -d 'OCR engine to use' -r -f -a "unstructured\t''
apple-native\t''
custom\t''"
complete -c screenpipe -n "__fish_screenpipe_using_subcommand add" -l metadata-override -d 'Path to JSON file containing metadata overrides' -r -F
complete -c screenpipe -n "__fish_screenpipe_using_subcommand add" -l copy-videos -d 'Copy videos to screenpipe data directory'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand add" -l debug -d 'Enable debug logging for screenpipe modules'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand add" -l use-embedding -d 'Enable embedding generation for OCR text'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand add" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and not __fish_seen_subcommand_from start pause stop status help" -l migration-name -d 'The name of the migration to run' -r
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and not __fish_seen_subcommand_from start pause stop status help" -l data-dir -d 'Data directory. Default to $HOME/.screenpipe' -r -f -a "(__fish_complete_directories)"
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and not __fish_seen_subcommand_from start pause stop status help" -s o -l output -d 'Output format' -r -f -a "text\t''
json\t''"
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and not __fish_seen_subcommand_from start pause stop status help" -l batch-size -d 'Batch size for processing records' -r
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and not __fish_seen_subcommand_from start pause stop status help" -l batch-delay-ms -d 'Delay between batches in milliseconds' -r
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and not __fish_seen_subcommand_from start pause stop status help" -l continue-on-error -d 'Continue processing if errors occur'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and not __fish_seen_subcommand_from start pause stop status help" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and not __fish_seen_subcommand_from start pause stop status help" -f -a "start" -d 'Start or resume a migration'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and not __fish_seen_subcommand_from start pause stop status help" -f -a "pause" -d 'Pause a running migration'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and not __fish_seen_subcommand_from start pause stop status help" -f -a "stop" -d 'Stop a running migration'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and not __fish_seen_subcommand_from start pause stop status help" -f -a "status" -d 'Get migration status'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and not __fish_seen_subcommand_from start pause stop status help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and __fish_seen_subcommand_from start" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and __fish_seen_subcommand_from pause" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and __fish_seen_subcommand_from stop" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and __fish_seen_subcommand_from status" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and __fish_seen_subcommand_from help" -f -a "start" -d 'Start or resume a migration'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and __fish_seen_subcommand_from help" -f -a "pause" -d 'Pause a running migration'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and __fish_seen_subcommand_from help" -f -a "stop" -d 'Stop a running migration'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and __fish_seen_subcommand_from help" -f -a "status" -d 'Get migration status'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand migrate; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand completions" -s h -l help -d 'Print help'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and not __fish_seen_subcommand_from audio vision pipe mcp add migrate completions help" -f -a "audio" -d 'Audio device management commands'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and not __fish_seen_subcommand_from audio vision pipe mcp add migrate completions help" -f -a "vision" -d 'Vision device management commands'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and not __fish_seen_subcommand_from audio vision pipe mcp add migrate completions help" -f -a "pipe" -d 'Pipe management commands'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and not __fish_seen_subcommand_from audio vision pipe mcp add migrate completions help" -f -a "mcp" -d 'MCP Server management commands'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and not __fish_seen_subcommand_from audio vision pipe mcp add migrate completions help" -f -a "add" -d 'Add video files to existing screenpipe data (OCR only) - DOES NOT SUPPORT AUDIO'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and not __fish_seen_subcommand_from audio vision pipe mcp add migrate completions help" -f -a "migrate" -d 'Run data migrations in the background'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and not __fish_seen_subcommand_from audio vision pipe mcp add migrate completions help" -f -a "completions" -d 'Generate shell completions'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and not __fish_seen_subcommand_from audio vision pipe mcp add migrate completions help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from audio" -f -a "list" -d 'List available audio devices'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from vision" -f -a "list" -d 'List available monitors and vision devices'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from pipe" -f -a "list" -d 'List all pipes'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from pipe" -f -a "download" -d 'Download a new pipe (deprecated: use \'install\' instead)'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from pipe" -f -a "install" -d 'Install a new pipe'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from pipe" -f -a "info" -d 'Get info for a specific pipe'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from pipe" -f -a "enable" -d 'Enable a pipe'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from pipe" -f -a "disable" -d 'Disable a pipe'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from pipe" -f -a "update" -d 'Update pipe configuration'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from pipe" -f -a "purge" -d 'Purge all pipes'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from pipe" -f -a "delete" -d 'Delete a pipe'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from mcp" -f -a "setup" -d 'Setup MCP server configuration'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from migrate" -f -a "start" -d 'Start or resume a migration'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from migrate" -f -a "pause" -d 'Pause a running migration'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from migrate" -f -a "stop" -d 'Stop a running migration'
complete -c screenpipe -n "__fish_screenpipe_using_subcommand help; and __fish_seen_subcommand_from migrate" -f -a "status" -d 'Get migration status'
