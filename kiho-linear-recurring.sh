#!/bin/bash
# Linear API documentation:
#   https://developers.linear.app/docs/graphql/working-with-the-graphql-api
# Use GraphQL understanding app like Insomnia to develop script further.
#
set -e
set -u

# Read Linear API key from config file:
API_KEY=$(cat kiho-linear-recurring.cfg)
API_URL="https://api.linear.app/graphql"


# Use curl to POST data:
# -X: Specify request type, here POST
# -s: Make curl silent, i.e do not print progress bars and the like
# -o /dev/null: Redirect response body into '/dev/null'
# -D -:         Dump headers into file, here stdout
# -H: Specify HTTP headers
# -d: Response data, JSON body
function http_post ()
{
	local payload="$1"
	# echo -e "HTTP POST PAYLOAD:\n'''\n$payload\n'''" >&2
	/usr/bin/curl \
		--request POST \
		--url                   "$API_URL" \
		--header "Authorization: $API_KEY" \
		--header "Content-Type: application/json" \
		--data "$payload" \
		--silent
}

function http_post_file ()
{
	local jsonfile="$1"
	/usr/bin/curl \
		--request POST \
		--url                   "$API_URL" \
		--header "Authorization: $API_KEY" \
		--header "Content-Type: application/json" \
		--data @"$jsonfile"
}

function print_data ()
{
	local head="${1^^}" # Echo header always in UPPERCASE
	local data="$2"
	for LN in "$head" "'''" "$data" "'''"; do
		echo "$LN"
	done
}


### Get ALL Users
# http_post '{ "query": "{ users { nodes { id name } } }" }' | jq -r '.data.users.nodes[] | [.id, .name] | @csv'
# MCLANG='108b8595-9a96-421f-b826-3ecbeae188b4'

### Get ALL Teams:
# http_post '{ "query": "{ teams { nodes { id name } } }" }' | jq -r '.data.teams.nodes[] | [.id, .name] | @csv'
TEAM_MCL='98c9f31b-0d35-44f1-875c-6a53d75fc58a'
# TEAM_SYS='c51cf4eb-d327-49ae-a8c5-866290ec879a'
# TEAM_IOT='e9fea5ce-6dc7-4c80-b54c-30f9fdcf7772'

### Get ALL the issues assigned to the selected team:
# http_post "{ \"query\": \"{ team (id: \\\"$TEAM_MCL\\\") { issues { nodes { identifier title state { name} }}}}\"}" | jq -cr '.data.team.issues.nodes[] | [.identifier, .title, .state.name] | @tsv'

### Get issues with certain TITLE that are NOT 'Canceled' or 'Done'
# http_post "{ \"query\": \"{ issues(filter: { title: { eq: \\\"Thursday - 2022-05-19\\\" } state: { name: { nin: [\\\"Canceled\\\", \\\"Done\\\"] } } }) { nodes { identifier title state { name} }}}\" }"
# exit

### Get templates for the team
# http_post "{ \"query\": \"{ team (id: \\\"$TEAM_MCL\\\") { templates { nodes {id name description } } } }\"}" | jq -cr '.data.team.templates.nodes[] | [.id, .name, .description] | @tsv'
# TODO: Select only the ones starting with 'Every-'


# Array of templates for recurring issues.
# Take the IDs from e.g the template edit link.
TEMPLATES=(
	"ef042038-217a-47e5-98c0-bb95a07b006c"  # Every Monday
	"4fc0d53e-8f99-4f8b-a57c-aa6624678254"  # Every Tuesday
	"4514528a-6d29-4dca-9412-d55a89cd7b38"  # Every Wednesday
	"209da9c4-ef97-42e7-aeb5-d9d8c39d5e4c"  # Every Friday
#	"f9cb7ada-be96-48d1-972b-ea0276b5cbc8"  # Test template
)

TEAMID="$TEAM_MCL"
PARENT=""   # Testin API 101 (MCL-22): 3a7702ec-47e6-4d94-ae0b-b68196cbf8c7
for TPLID in "${TEMPLATES[@]}"; do
	echo "GETTING TEMPLATE DATA FOR '$TPLID'..."
	QUERY="{ \"query\":\"query { template(id: \\\"${TPLID}\\\") { templateData }}\" }"
	TDATA=$(http_post "$QUERY" | jq -cr '.data.template.templateData')
	# print_data "RAW TEMPLATE DATA" "$TDATA"
	TITLE=$(echo "$TDATA" | jq -cr '.title')
	DESCD=$(echo "$TDATA" | jq -cr '.descriptionData' | sed 's/"/\\\\\\"/g')    # Replaces all `"` in description data with `\\\"`
	ASSID=$(echo "$TDATA" | jq -cr '.assigneeId')
	STAID=$(echo "$TDATA" | jq -cr '.stateId')
	PRIOR=$(echo "$TDATA" | jq -cr '.priority')
	DUEDATE=$(date +'%F' --date "${TITLE}")
	ESTIMATE="2"
	echo "Template title: '$TITLE'"
	echo "Assignee:       '$ASSID'"
	echo "State ID:       '$STAID'"
	echo "Priority:       '$PRIOR'"
	echo "Due date:       '$DUEDATE'"
	echo "Estimate:       '$ESTIMATE'"
	TITLE="$DUEDATE - ${TITLE}"
	QUERY="{ \"query\": \"{ issues(filter: { title: { eq: \\\"${TITLE}\\\" } state: { name: { nin: [\\\"Canceled\\\", \\\"Done\\\"] } } }) { nodes { identifier title state { name} }}}\" }"
	RESULT=$(http_post "$QUERY" | jq '.data.issues.nodes | length')
	if (( RESULT > 0 )); then
		echo "==> SKIPPING - Issue '$TITLE' exists already!"
		continue
	else
		echo "==> Creating issue '$TITLE'"
	fi
	if [[ -z "$PARENT" ]]; then
		QUERY="{ \"query\": \"mutation IssueCreate { issueCreate( input: { title: \\\"${TITLE}\\\" descriptionData: \\\"${DESCD}\\\" teamId: \\\"${TEAMID}\\\" assigneeId: \\\"${ASSID}\\\"                             stateId: \\\"${STAID}\\\" dueDate: \\\"${DUEDATE}\\\" estimate: $ESTIMATE priority: $PRIOR }) { success issue {identifier state {name}} } }\" }"
	else
		QUERY="{ \"query\": \"mutation IssueCreate { issueCreate( input: { title: \\\"${TITLE}\\\" descriptionData: \\\"${DESCD}\\\" teamId: \\\"${TEAMID}\\\" assigneeId: \\\"${ASSID}\\\" parentId: \\\"${PARENT}\\\" stateId: \\\"${STAID}\\\" dueDate: \\\"${DUEDATE}\\\" estimate: $ESTIMATE priority: $PRIOR }) { success issue {identifier state {name}} } }\" }"
	fi
	# print_data "create issue query" "$QUERY"
	echo "$QUERY" > kiho-linear-recurring.json
	RESULT=$(http_post "$QUERY")
	# print_data "create issue result" "$RESULT"
	echo "==> Success: $(echo "$RESULT" | jq -cr '.data.issueCreate | [.success, .issue.identifier, .issue.state.name] | @csv')"
done
