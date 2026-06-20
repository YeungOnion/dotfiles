# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_shuttle_global_optspecs
	string join \n api-url= offline debug working-directory= name= h/help V/version
end

function __fish_shuttle_needs_command
	# Figure out if the current invocation already has a command.
	set -l cmd (commandline -opc)
	set -e cmd[1]
	argparse -s (__fish_shuttle_global_optspecs) -- $cmd 2>/dev/null
	or return
	if set -q argv[1]
		# Also print the command, so this can be used to figure out what it is.
		echo $argv[1]
		return 1
	end
	return 0
end

function __fish_shuttle_using_subcommand
	set -l cmd (__fish_shuttle_needs_command)
	test -z "$cmd"
	and return 1
	contains -- $cmd[1] $argv
end

complete -c shuttle -n "__fish_shuttle_needs_command" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_needs_command" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_needs_command" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_needs_command" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_needs_command" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_needs_command" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c shuttle -n "__fish_shuttle_needs_command" -s V -l version -d 'Print version'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "init" -d 'Generate a Shuttle project from a template'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "run" -d 'Run a project locally'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "deploy" -d 'Deploy a project'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "deployment" -d 'Manage deployments'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "depl" -d 'Manage deployments'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "logs" -d 'View build and deployment logs'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "project" -d 'Manage Shuttle projects'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "proj" -d 'Manage Shuttle projects'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "resource" -d 'Manage resources'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "res" -d 'Manage resources'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "certificate" -d 'Manage SSL certificates for custom domains'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "cert" -d 'Manage SSL certificates for custom domains'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "account" -d 'Show info about your Shuttle account'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "acc" -d 'Show info about your Shuttle account'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "login" -d 'Log in to the Shuttle platform'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "logout" -d 'Log out of the Shuttle platform'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "generate" -d 'Generate shell completions and man page'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "feedback" -d 'Open an issue on GitHub and provide feedback'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "upgrade" -d 'Upgrade the Shuttle CLI binary'
complete -c shuttle -n "__fish_shuttle_needs_command" -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand init" -s t -l template -d 'Clone a starter template from Shuttle\'s official examples' -r -f -a "axum\t'Axum - Modular web framework from the Tokio ecosystem'
actix-web\t'Actix Web - Powerful and fast web framework'
rocket\t'Rocket - Simple and easy-to-use web framework'
loco\t'Loco - Batteries included web framework based on Axum'
salvo\t'Salvo - Powerful and simple web framework'
poem\t'Poem - Full-featured and easy-to-use web framework'
poise\t'Poise - Discord Bot framework with good slash command support'
serenity\t'Serenity - Discord Bot framework'
tower\t'Tower - Modular service library'
thruster\t'Thruster - Web framework'
tide\t'Tide - Web framework'
warp\t'Warp - Web framework'
none\t'No template - Make a custom service'"
complete -c shuttle -n "__fish_shuttle_using_subcommand init" -l from -d 'Clone a template from a git repository or local path using cargo-generate' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand init" -l subfolder -d 'Path to the template in the source (used with --from)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand init" -l api-key -d 'Log in with this Shuttle API key' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand init" -l console-url -d 'URL to the Shuttle Console for automatic login' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand init" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand init" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand init" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand init" -l force-name -d 'Don\'t check the project name\'s validity or availability and use it anyways'
complete -c shuttle -n "__fish_shuttle_using_subcommand init" -l create-env -d 'Whether to start the container for this project on Shuttle, and claim the project name'
complete -c shuttle -n "__fish_shuttle_using_subcommand init" -l no-git -d 'Don\'t initialize a new git repository'
complete -c shuttle -n "__fish_shuttle_using_subcommand init" -l prompt -d 'Prompt to paste the API key instead of opening the browser'
complete -c shuttle -n "__fish_shuttle_using_subcommand init" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand init" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand init" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c shuttle -n "__fish_shuttle_using_subcommand run" -s p -l port -d 'Port to start service on' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand run" -l secrets -d 'Use this secrets file instead' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand run" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand run" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand run" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand run" -l external -d 'Use 0.0.0.0 instead of localhost (for usage with local external devices)'
complete -c shuttle -n "__fish_shuttle_using_subcommand run" -s r -l release -d 'Use release mode for building the project'
complete -c shuttle -n "__fish_shuttle_using_subcommand run" -l raw -d 'Don\'t display timestamps and log origin tags'
complete -c shuttle -n "__fish_shuttle_using_subcommand run" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand run" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand run" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand deploy" -s i -l image -d 'WIP: Deploy this Docker image instead of building one' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deploy" -l output-archive -d 'Output the deployment archive to a file instead of sending a deployment request' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand deploy" -l secrets -d 'Use this secrets file instead' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand deploy" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deploy" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand deploy" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deploy" -l allow-dirty -l ad -d 'Allow deployment with uncommitted files'
complete -c shuttle -n "__fish_shuttle_using_subcommand deploy" -l no-follow -l nf -d 'Don\'t follow the deployment status, exit after the operation begins'
complete -c shuttle -n "__fish_shuttle_using_subcommand deploy" -l raw -d 'Don\'t display timestamps and log origin tags'
complete -c shuttle -n "__fish_shuttle_using_subcommand deploy" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand deploy" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand deploy" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -f -a "list" -d 'List the deployments for a service'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -f -a "ls" -d 'List the deployments for a service'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -f -a "status" -d 'View status of a deployment'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -f -a "stat" -d 'View status of a deployment'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -f -a "redeploy" -d 'Redeploy a previous deployment (if possible)'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -f -a "stop" -d 'Stop running deployment(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from list" -l page -d 'Which page to display' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from list" -l limit -l per-page -d 'How many deployments per page to display' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from list" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from list" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from list" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from list" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from list" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from list" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from ls" -l page -d 'Which page to display' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from ls" -l limit -l per-page -d 'How many deployments per page to display' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from ls" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from ls" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from ls" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from ls" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from ls" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from ls" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from ls" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from status" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from status" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from status" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from status" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from status" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from status" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from stat" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from stat" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from stat" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from stat" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from stat" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from stat" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from redeploy" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from redeploy" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from redeploy" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from redeploy" -l no-follow -l nf -d 'Don\'t follow the deployment status, exit after the operation begins'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from redeploy" -l raw -d 'Don\'t display timestamps and log origin tags'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from redeploy" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from redeploy" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from redeploy" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from stop" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from stop" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from stop" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from stop" -l no-follow -l nf -d 'Don\'t follow the deployment status, exit after the operation begins'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from stop" -l raw -d 'Don\'t display timestamps and log origin tags'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from stop" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from stop" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from stop" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from help" -f -a "list" -d 'List the deployments for a service'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from help" -f -a "status" -d 'View status of a deployment'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from help" -f -a "redeploy" -d 'Redeploy a previous deployment (if possible)'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from help" -f -a "stop" -d 'Stop running deployment(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand deployment; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -f -a "list" -d 'List the deployments for a service'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -f -a "ls" -d 'List the deployments for a service'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -f -a "status" -d 'View status of a deployment'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -f -a "stat" -d 'View status of a deployment'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -f -a "redeploy" -d 'Redeploy a previous deployment (if possible)'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -f -a "stop" -d 'Stop running deployment(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and not __fish_seen_subcommand_from list ls status stat redeploy stop help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from list" -l page -d 'Which page to display' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from list" -l limit -l per-page -d 'How many deployments per page to display' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from list" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from list" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from list" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from list" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from list" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from list" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from ls" -l page -d 'Which page to display' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from ls" -l limit -l per-page -d 'How many deployments per page to display' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from ls" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from ls" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from ls" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from ls" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from ls" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from ls" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from ls" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from status" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from status" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from status" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from status" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from status" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from status" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from stat" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from stat" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from stat" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from stat" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from stat" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from stat" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from redeploy" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from redeploy" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from redeploy" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from redeploy" -l no-follow -l nf -d 'Don\'t follow the deployment status, exit after the operation begins'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from redeploy" -l raw -d 'Don\'t display timestamps and log origin tags'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from redeploy" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from redeploy" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from redeploy" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from stop" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from stop" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from stop" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from stop" -l no-follow -l nf -d 'Don\'t follow the deployment status, exit after the operation begins'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from stop" -l raw -d 'Don\'t display timestamps and log origin tags'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from stop" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from stop" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from stop" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from help" -f -a "list" -d 'List the deployments for a service'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from help" -f -a "status" -d 'View status of a deployment'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from help" -f -a "redeploy" -d 'Redeploy a previous deployment (if possible)'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from help" -f -a "stop" -d 'Stop running deployment(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand depl; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand logs" -l head -d 'View the first N log lines' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand logs" -l tail -d 'View the last N log lines' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand logs" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand logs" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand logs" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand logs" -s l -l latest -d 'View logs from the most recent deployment (which is not always the latest running one)'
complete -c shuttle -n "__fish_shuttle_using_subcommand logs" -s f -l follow -d 'Follow log output'
complete -c shuttle -n "__fish_shuttle_using_subcommand logs" -l raw -d 'Don\'t display timestamps and log origin tags'
complete -c shuttle -n "__fish_shuttle_using_subcommand logs" -l all -d 'View all log lines'
complete -c shuttle -n "__fish_shuttle_using_subcommand logs" -l all-deployments -d 'Get logs from all deployments instead of one deployment'
complete -c shuttle -n "__fish_shuttle_using_subcommand logs" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand logs" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand logs" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "create" -d 'Create a project on Shuttle'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "start" -d 'Create a project on Shuttle'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "update" -d 'Update project config'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "upd" -d 'Update project config'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "status" -d 'Get the status of this project on Shuttle'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "stat" -d 'Get the status of this project on Shuttle'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "list" -d 'List all projects you have access to'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "ls" -d 'List all projects you have access to'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "delete" -d 'Delete a project and all linked data'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "rm" -d 'Delete a project and all linked data'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "link" -d 'Link this workspace to a Shuttle project'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from create" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from create" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from create" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from create" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from create" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from create" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from start" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from start" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from start" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from start" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from start" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from start" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from update" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from update" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from update" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from update" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from update" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from update" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from update" -f -a "name" -d 'Rename the project, including its default subdomain'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from update" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from upd" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from upd" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from upd" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from upd" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from upd" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from upd" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from upd" -f -a "name" -d 'Rename the project, including its default subdomain'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from upd" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from status" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from status" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from status" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from status" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from status" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from status" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from stat" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from stat" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from stat" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from stat" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from stat" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from stat" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from list" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from list" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from list" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from list" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from list" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from list" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from ls" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from ls" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from ls" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from ls" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from ls" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from ls" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from ls" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from delete" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from delete" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from delete" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from delete" -s y -l yes -d 'Skip confirmations and proceed'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from delete" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from delete" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from rm" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from rm" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from rm" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from rm" -s y -l yes -d 'Skip confirmations and proceed'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from rm" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from rm" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from rm" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from link" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from link" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from link" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from link" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from link" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from link" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from help" -f -a "create" -d 'Create a project on Shuttle'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from help" -f -a "update" -d 'Update project config'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from help" -f -a "status" -d 'Get the status of this project on Shuttle'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from help" -f -a "list" -d 'List all projects you have access to'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete a project and all linked data'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from help" -f -a "link" -d 'Link this workspace to a Shuttle project'
complete -c shuttle -n "__fish_shuttle_using_subcommand project; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "create" -d 'Create a project on Shuttle'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "start" -d 'Create a project on Shuttle'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "update" -d 'Update project config'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "upd" -d 'Update project config'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "status" -d 'Get the status of this project on Shuttle'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "stat" -d 'Get the status of this project on Shuttle'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "list" -d 'List all projects you have access to'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "ls" -d 'List all projects you have access to'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "delete" -d 'Delete a project and all linked data'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "rm" -d 'Delete a project and all linked data'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "link" -d 'Link this workspace to a Shuttle project'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and not __fish_seen_subcommand_from create start update upd status stat list ls delete rm link help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from create" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from create" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from create" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from create" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from create" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from create" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from start" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from start" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from start" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from start" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from start" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from start" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from update" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from update" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from update" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from update" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from update" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from update" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from update" -f -a "name" -d 'Rename the project, including its default subdomain'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from update" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from upd" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from upd" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from upd" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from upd" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from upd" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from upd" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from upd" -f -a "name" -d 'Rename the project, including its default subdomain'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from upd" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from status" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from status" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from status" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from status" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from status" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from status" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from stat" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from stat" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from stat" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from stat" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from stat" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from stat" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from list" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from list" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from list" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from list" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from list" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from list" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from ls" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from ls" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from ls" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from ls" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from ls" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from ls" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from ls" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from delete" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from delete" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from delete" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from delete" -s y -l yes -d 'Skip confirmations and proceed'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from delete" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from delete" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from rm" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from rm" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from rm" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from rm" -s y -l yes -d 'Skip confirmations and proceed'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from rm" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from rm" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from rm" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from link" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from link" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from link" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from link" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from link" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from link" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from help" -f -a "create" -d 'Create a project on Shuttle'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from help" -f -a "update" -d 'Update project config'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from help" -f -a "status" -d 'Get the status of this project on Shuttle'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from help" -f -a "list" -d 'List all projects you have access to'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete a project and all linked data'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from help" -f -a "link" -d 'Link this workspace to a Shuttle project'
complete -c shuttle -n "__fish_shuttle_using_subcommand proj; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and not __fish_seen_subcommand_from list ls delete rm dump help" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and not __fish_seen_subcommand_from list ls delete rm dump help" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and not __fish_seen_subcommand_from list ls delete rm dump help" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and not __fish_seen_subcommand_from list ls delete rm dump help" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and not __fish_seen_subcommand_from list ls delete rm dump help" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and not __fish_seen_subcommand_from list ls delete rm dump help" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and not __fish_seen_subcommand_from list ls delete rm dump help" -f -a "list" -d 'List the resources for a project'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and not __fish_seen_subcommand_from list ls delete rm dump help" -f -a "ls" -d 'List the resources for a project'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and not __fish_seen_subcommand_from list ls delete rm dump help" -f -a "delete" -d 'Delete a resource'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and not __fish_seen_subcommand_from list ls delete rm dump help" -f -a "rm" -d 'Delete a resource'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and not __fish_seen_subcommand_from list ls delete rm dump help" -f -a "dump" -d 'Dump a resource'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and not __fish_seen_subcommand_from list ls delete rm dump help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from list" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from list" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from list" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from list" -l show-secrets -d 'Show secrets from resources (e.g. a password in a connection string)'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from list" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from list" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from list" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from ls" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from ls" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from ls" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from ls" -l show-secrets -d 'Show secrets from resources (e.g. a password in a connection string)'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from ls" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from ls" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from ls" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from ls" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from delete" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from delete" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from delete" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from delete" -s y -l yes -d 'Skip confirmations and proceed'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from delete" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from delete" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from rm" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from rm" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from rm" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from rm" -s y -l yes -d 'Skip confirmations and proceed'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from rm" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from rm" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from rm" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from dump" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from dump" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from dump" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from dump" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from dump" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from dump" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from help" -f -a "list" -d 'List the resources for a project'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete a resource'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from help" -f -a "dump" -d 'Dump a resource'
complete -c shuttle -n "__fish_shuttle_using_subcommand resource; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and not __fish_seen_subcommand_from list ls delete rm dump help" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and not __fish_seen_subcommand_from list ls delete rm dump help" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and not __fish_seen_subcommand_from list ls delete rm dump help" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and not __fish_seen_subcommand_from list ls delete rm dump help" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and not __fish_seen_subcommand_from list ls delete rm dump help" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and not __fish_seen_subcommand_from list ls delete rm dump help" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and not __fish_seen_subcommand_from list ls delete rm dump help" -f -a "list" -d 'List the resources for a project'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and not __fish_seen_subcommand_from list ls delete rm dump help" -f -a "ls" -d 'List the resources for a project'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and not __fish_seen_subcommand_from list ls delete rm dump help" -f -a "delete" -d 'Delete a resource'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and not __fish_seen_subcommand_from list ls delete rm dump help" -f -a "rm" -d 'Delete a resource'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and not __fish_seen_subcommand_from list ls delete rm dump help" -f -a "dump" -d 'Dump a resource'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and not __fish_seen_subcommand_from list ls delete rm dump help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from list" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from list" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from list" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from list" -l show-secrets -d 'Show secrets from resources (e.g. a password in a connection string)'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from list" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from list" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from list" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from ls" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from ls" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from ls" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from ls" -l show-secrets -d 'Show secrets from resources (e.g. a password in a connection string)'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from ls" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from ls" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from ls" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from ls" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from delete" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from delete" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from delete" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from delete" -s y -l yes -d 'Skip confirmations and proceed'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from delete" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from delete" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from rm" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from rm" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from rm" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from rm" -s y -l yes -d 'Skip confirmations and proceed'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from rm" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from rm" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from rm" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from dump" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from dump" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from dump" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from dump" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from dump" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from dump" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from help" -f -a "list" -d 'List the resources for a project'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete a resource'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from help" -f -a "dump" -d 'Dump a resource'
complete -c shuttle -n "__fish_shuttle_using_subcommand res; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and not __fish_seen_subcommand_from add list ls delete rm help" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and not __fish_seen_subcommand_from add list ls delete rm help" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and not __fish_seen_subcommand_from add list ls delete rm help" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and not __fish_seen_subcommand_from add list ls delete rm help" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and not __fish_seen_subcommand_from add list ls delete rm help" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and not __fish_seen_subcommand_from add list ls delete rm help" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and not __fish_seen_subcommand_from add list ls delete rm help" -f -a "add" -d 'Add an SSL certificate for a custom domain'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and not __fish_seen_subcommand_from add list ls delete rm help" -f -a "list" -d 'List the certificates for a project'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and not __fish_seen_subcommand_from add list ls delete rm help" -f -a "ls" -d 'List the certificates for a project'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and not __fish_seen_subcommand_from add list ls delete rm help" -f -a "delete" -d 'Delete an SSL certificate'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and not __fish_seen_subcommand_from add list ls delete rm help" -f -a "rm" -d 'Delete an SSL certificate'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and not __fish_seen_subcommand_from add list ls delete rm help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from add" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from add" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from add" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from add" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from add" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from add" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from list" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from list" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from list" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from list" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from list" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from list" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from ls" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from ls" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from ls" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from ls" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from ls" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from ls" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from ls" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from delete" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from delete" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from delete" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from delete" -s y -l yes -d 'Skip confirmations and proceed'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from delete" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from delete" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from rm" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from rm" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from rm" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from rm" -s y -l yes -d 'Skip confirmations and proceed'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from rm" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from rm" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from rm" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from help" -f -a "add" -d 'Add an SSL certificate for a custom domain'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from help" -f -a "list" -d 'List the certificates for a project'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete an SSL certificate'
complete -c shuttle -n "__fish_shuttle_using_subcommand certificate; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and not __fish_seen_subcommand_from add list ls delete rm help" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and not __fish_seen_subcommand_from add list ls delete rm help" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and not __fish_seen_subcommand_from add list ls delete rm help" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and not __fish_seen_subcommand_from add list ls delete rm help" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and not __fish_seen_subcommand_from add list ls delete rm help" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and not __fish_seen_subcommand_from add list ls delete rm help" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and not __fish_seen_subcommand_from add list ls delete rm help" -f -a "add" -d 'Add an SSL certificate for a custom domain'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and not __fish_seen_subcommand_from add list ls delete rm help" -f -a "list" -d 'List the certificates for a project'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and not __fish_seen_subcommand_from add list ls delete rm help" -f -a "ls" -d 'List the certificates for a project'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and not __fish_seen_subcommand_from add list ls delete rm help" -f -a "delete" -d 'Delete an SSL certificate'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and not __fish_seen_subcommand_from add list ls delete rm help" -f -a "rm" -d 'Delete an SSL certificate'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and not __fish_seen_subcommand_from add list ls delete rm help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from add" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from add" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from add" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from add" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from add" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from add" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from list" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from list" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from list" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from list" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from list" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from list" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from ls" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from ls" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from ls" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from ls" -l raw -d 'Output tables without borders'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from ls" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from ls" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from ls" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from delete" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from delete" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from delete" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from delete" -s y -l yes -d 'Skip confirmations and proceed'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from delete" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from delete" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from rm" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from rm" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from rm" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from rm" -s y -l yes -d 'Skip confirmations and proceed'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from rm" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from rm" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from rm" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from help" -f -a "add" -d 'Add an SSL certificate for a custom domain'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from help" -f -a "list" -d 'List the certificates for a project'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete an SSL certificate'
complete -c shuttle -n "__fish_shuttle_using_subcommand cert; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand account" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand account" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand account" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand account" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand account" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand account" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand acc" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand acc" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand acc" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand acc" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand acc" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand acc" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand login" -l api-key -d 'Log in with this Shuttle API key' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand login" -l console-url -d 'URL to the Shuttle Console for automatic login' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand login" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand login" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand login" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand login" -l prompt -d 'Prompt to paste the API key instead of opening the browser'
complete -c shuttle -n "__fish_shuttle_using_subcommand login" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand login" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand login" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand logout" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand logout" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand logout" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand logout" -l reset-api-key -d 'Reset the API key before logging out'
complete -c shuttle -n "__fish_shuttle_using_subcommand logout" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand logout" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand logout" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and not __fish_seen_subcommand_from shell manpage help" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and not __fish_seen_subcommand_from shell manpage help" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and not __fish_seen_subcommand_from shell manpage help" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and not __fish_seen_subcommand_from shell manpage help" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and not __fish_seen_subcommand_from shell manpage help" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and not __fish_seen_subcommand_from shell manpage help" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and not __fish_seen_subcommand_from shell manpage help" -f -a "shell" -d 'Generate shell completions'
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and not __fish_seen_subcommand_from shell manpage help" -f -a "manpage" -d 'Generate man page to the standard output'
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and not __fish_seen_subcommand_from shell manpage help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from shell" -s o -l output -d 'Output to a file (stdout by default)' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from shell" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from shell" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from shell" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from shell" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from shell" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from shell" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from manpage" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from manpage" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from manpage" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from manpage" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from manpage" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from manpage" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from help" -f -a "shell" -d 'Generate shell completions'
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from help" -f -a "manpage" -d 'Generate man page to the standard output'
complete -c shuttle -n "__fish_shuttle_using_subcommand generate; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand feedback" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand feedback" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand feedback" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand feedback" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand feedback" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand feedback" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand upgrade" -l api-url -d 'URL for the Shuttle API to target (mainly for development)' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand upgrade" -l working-directory -l wd -d 'Specify the working directory' -r -F
complete -c shuttle -n "__fish_shuttle_using_subcommand upgrade" -l name -l id -d 'Specify the name or id of the project' -r
complete -c shuttle -n "__fish_shuttle_using_subcommand upgrade" -l preview -d 'Install an unreleased version from the repository\'s main branch'
complete -c shuttle -n "__fish_shuttle_using_subcommand upgrade" -l offline -d 'Disable network requests that are not strictly necessary. Limits some features'
complete -c shuttle -n "__fish_shuttle_using_subcommand upgrade" -l debug -d 'Turn on tracing output for Shuttle libraries. (WARNING: can print sensitive data)'
complete -c shuttle -n "__fish_shuttle_using_subcommand upgrade" -s h -l help -d 'Print help'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and not __fish_seen_subcommand_from init run deploy deployment logs project resource certificate account login logout generate feedback upgrade help" -f -a "init" -d 'Generate a Shuttle project from a template'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and not __fish_seen_subcommand_from init run deploy deployment logs project resource certificate account login logout generate feedback upgrade help" -f -a "run" -d 'Run a project locally'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and not __fish_seen_subcommand_from init run deploy deployment logs project resource certificate account login logout generate feedback upgrade help" -f -a "deploy" -d 'Deploy a project'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and not __fish_seen_subcommand_from init run deploy deployment logs project resource certificate account login logout generate feedback upgrade help" -f -a "deployment" -d 'Manage deployments'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and not __fish_seen_subcommand_from init run deploy deployment logs project resource certificate account login logout generate feedback upgrade help" -f -a "logs" -d 'View build and deployment logs'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and not __fish_seen_subcommand_from init run deploy deployment logs project resource certificate account login logout generate feedback upgrade help" -f -a "project" -d 'Manage Shuttle projects'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and not __fish_seen_subcommand_from init run deploy deployment logs project resource certificate account login logout generate feedback upgrade help" -f -a "resource" -d 'Manage resources'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and not __fish_seen_subcommand_from init run deploy deployment logs project resource certificate account login logout generate feedback upgrade help" -f -a "certificate" -d 'Manage SSL certificates for custom domains'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and not __fish_seen_subcommand_from init run deploy deployment logs project resource certificate account login logout generate feedback upgrade help" -f -a "account" -d 'Show info about your Shuttle account'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and not __fish_seen_subcommand_from init run deploy deployment logs project resource certificate account login logout generate feedback upgrade help" -f -a "login" -d 'Log in to the Shuttle platform'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and not __fish_seen_subcommand_from init run deploy deployment logs project resource certificate account login logout generate feedback upgrade help" -f -a "logout" -d 'Log out of the Shuttle platform'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and not __fish_seen_subcommand_from init run deploy deployment logs project resource certificate account login logout generate feedback upgrade help" -f -a "generate" -d 'Generate shell completions and man page'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and not __fish_seen_subcommand_from init run deploy deployment logs project resource certificate account login logout generate feedback upgrade help" -f -a "feedback" -d 'Open an issue on GitHub and provide feedback'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and not __fish_seen_subcommand_from init run deploy deployment logs project resource certificate account login logout generate feedback upgrade help" -f -a "upgrade" -d 'Upgrade the Shuttle CLI binary'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and not __fish_seen_subcommand_from init run deploy deployment logs project resource certificate account login logout generate feedback upgrade help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from deployment" -f -a "list" -d 'List the deployments for a service'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from deployment" -f -a "status" -d 'View status of a deployment'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from deployment" -f -a "redeploy" -d 'Redeploy a previous deployment (if possible)'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from deployment" -f -a "stop" -d 'Stop running deployment(s)'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from project" -f -a "create" -d 'Create a project on Shuttle'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from project" -f -a "update" -d 'Update project config'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from project" -f -a "status" -d 'Get the status of this project on Shuttle'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from project" -f -a "list" -d 'List all projects you have access to'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from project" -f -a "delete" -d 'Delete a project and all linked data'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from project" -f -a "link" -d 'Link this workspace to a Shuttle project'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from resource" -f -a "list" -d 'List the resources for a project'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from resource" -f -a "delete" -d 'Delete a resource'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from resource" -f -a "dump" -d 'Dump a resource'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from certificate" -f -a "add" -d 'Add an SSL certificate for a custom domain'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from certificate" -f -a "list" -d 'List the certificates for a project'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from certificate" -f -a "delete" -d 'Delete an SSL certificate'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from generate" -f -a "shell" -d 'Generate shell completions'
complete -c shuttle -n "__fish_shuttle_using_subcommand help; and __fish_seen_subcommand_from generate" -f -a "manpage" -d 'Generate man page to the standard output'
