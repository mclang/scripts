#!/bin/bash

# Tables that were reported corrupted/missing
# During the first migration attempt 04.05.2023:
TROUBLEMAKERS=(
	"MGPS.DEVICES_DRIVES"
	"MGPS.externalapi_settings_aditro"
	"MGPS.externalapi_settings_fennoa_wage_payment"
	"MGPS.externalapi_settings_heeros"
	"MGPS.externalapi_settings_lemonsoft"
	"MGPS.externalapi_settings_mepco"
	"MGPS.externalapi_settings_procountorwp"
	"MGPS.externalapi_settings_vismafivaldi"
	"MGPS.externalapi_settings_visma_ltr"
	"MGPS.job_results"
	"MGPS.jobs"
	"MGPS.overview_report_settings"
	"MGPS.PROFILE_DATA"
	"MGPS.rawworktimeline_log"
	"MGPS.rawworktimeprofile_wagecodematchingrules"
	"MGPS.statuscodes"
	"MGPS.ui_settings_profiles"
	"MGPS.valvo_event_data"
	"MGPS.vehicle_dtc"
)

for TABLE in "${TROUBLEMAKERS[@]}"; do
	echo "### $TABLE ###"
	DBASE=${TABLE%.*}
	TABLE=${TABLE#*.}
	mysqldump -u root "$DBASE" "$TABLE" | zstd -T0 -o "${DBASE}_${TABLE}_$(date --iso-8601).sql.zst"
	echo ""
done

