#!/bin/bash
# ---------------------------------------------------------------
# Copyright (C) 2021 King County Library System
# Bill Erickson <berickxx@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# Process XML notice Action/Trigger events, generate XML files 
# from events, and send XML notices to the vendor.
# Parameters are passed to the ./process-one-notice.sh script
# via environment variables.
# ---------------------------------------------------------------
source ~/.bashrc
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 
END_DATE=$(date +'%F');
FILE_DATE=""
SCP_DEST="my-account@sftp.exmaple.com:incoming"
AT_FILTERS="/openils/conf/a_t_filters/"
WINDOW=""
SKIP_ACTION_TRIGGER=""
NO_GENERATE_XML=""
FORCE_GENERATE_XML=""
SEND_XML=""
GRANULARITY=""
FOR_EMAIL=""
EVENT_DEF=""
NOTICE_TAG=""
NOTICE_TYPE=""
NOTIFY_INTERVAL=""
PROCESS_HOOKS=""
CUSTOM_FILTERS=""

function usage {

    cat <<USAGE

Synopsis:

    $0 --send-xml --granularity Checkout-Locker-Email

Options:

    --granularity   
        Action/Trigger granularity string.  Each event definition should
        have its own unique granularity for maximum control.

    --end-date <YYYY-MM-DD[Thh:mm:ss]>
        Process action/trigger events with a run time during the period
        of time ending with this date / time.  The full size of the 
        time range is specified by --window (defaults to 1 day).

    --file-date <YYYY-MM-DD[Thh:mm:ss]>
        Optional.  Overrides use of --end-date when naming the output file.

    --skip-action-trigger
        Avoid any A/T event processing.  Useful for resending notices.

    --no-generate-xml
        Skip XML generation.  Useful for redelivering existing files.

    --force-generate-xml
        Generate the XML notice files even in cases where a matching
        file already exists.

    --send-xml
        Deliver XML notice files to vendor via SCP.

    --window <interval>
        For notices which run more frequently than daily, specify the 
        time window to process so the correct events can be isolated.

    --help
        Show this message

USAGE

    exit 0
}

while [ "$#" -gt 0 ]; do
    case $1 in
        '--granularity') GRANULARITY="$2"; shift;;
        '--end-date') END_DATE="$2"; shift;;
        '--file-date') FILE_DATE="$2"; shift;;
        '--skip-action-trigger') SKIP_ACTION_TRIGGER="YES";;
        '--no-generate-xml') NO_GENERATE_XML="YES";;
        '--force-generate-xml') FORCE_GENERATE_XML="--force";;
        '--send-xml') SEND_XML="YES";;
        '--window') WINDOW="$2"; shift;;
        '--help') usage;;
        *) echo "Unknown parameter: $1"; usage;;
    esac;
    shift;
done

if [ -z "$GRANULARITY" ]; then
    echo "--granularity required"
    exit 1;
fi;

# Our support scripts live in the same directory as us.
cd "$SCRIPT_DIR"

# ----- Export defaults;  Some of these will be overridden below.-----

export SKIP_ACTION_TRIGGER
export NO_GENERATE_XML
export FORCE_GENERATE_XML
export SEND_XML
export SCP_DEST
export END_DATE
export FILE_DATE
export WINDOW
export GRANULARITY
export NOTICE_TYPE
export NOTIFY_INTERVAL
export PROCESS_HOOKS
export CUSTOM_FILTERS
export FOR_EMAIL

case $GRANULARITY in

    'Checkout-Locker-Email')
        export FOR_EMAIL="--for-email"
        export EVENT_DEF=232
        export NOTICE_TAG=checkout-locker-email
        export NOTICE_TYPE="checkout locker"
        ;;

    'Hold-Ready-Locker-Email')
        export FOR_EMAIL="--for-email"
        export EVENT_DEF=221
        export NOTICE_TAG=hold-ready-locker-email
        export NOTICE_TYPE="hold ready locker email"
        ;;

    'Hold-Ready-Locker-Phone')
        export EVENT_DEF=222
        export NOTICE_TAG=hold-ready-locker-phone
        export NOTICE_TYPE="hold ready locker phone"
        ;;

    'Hold-Ready-Email')
        export FOR_EMAIL="--for-email"
        export EVENT_DEF=234
        export NOTICE_TAG=hold-ready-email
        export NOTICE_TYPE="hold ready email"
        ;;

    'Checkout-Email')
        export FOR_EMAIL="--for-email"
        export EVENT_DEF=231
        export NOTICE_TAG=checkout-email
        export NOTICE_TYPE="checkout"
        ;;

    'Hold-Shelf-Expire-Email')
        export FOR_EMAIL="--for-email"
        export EVENT_DEF=233
        export NOTICE_TAG=hold-shelf-expire
        export NOTICE_TYPE="hold shelf expire email"
        ;;

    'Daily-Export-Hold-Cancel')
        export EVENT_DEF=220
        export NOTICE_TAG=hold-cancel-email
        export NOTICE_TYPE="hold canceled"
        ;;

    'Daily-Export-Billing-Outreach-Print')
        export EVENT_DEF=230
        export NOTICE_TAG="collection-outreach"
        export NOTICE_TYPE="collections"
        ;;

    'Daily-Export-OD-90-Print')
        export EVENT_DEF=229
        export NOTICE_TAG="90-day-overdue-print"
        export NOTICE_TYPE="overdue"
        export NOTIFY_INTERVAL="90 days"
        export PROCESS_HOOKS="--process-hooks"
        export CUSTOM_FILTERS="--custom-filters $AT_FILTERS/a_t_filters.outreach_od.json"
        ;;

    'Daily-Export-OD-60-Print')
        export EVENT_DEF=228
        export NOTICE_TAG="60-day-overdue-print"
        export NOTICE_TYPE="overdue"
        export NOTIFY_INTERVAL="60 days"
        export PROCESS_HOOKS="--process-hooks"
        export CUSTOM_FILTERS="--custom-filters $AT_FILTERS/a_t_filters.outreach_od.json"
        ;;
    
    'Daily-Export-Ecard-Print')
        export EVENT_DEF=227
        export NOTICE_TAG="ecard"
        export NOTICE_TYPE="ecard"
        ;;

    'Daily-Export-Billing-Print')
        export EVENT_DEF=226
        export NOTICE_TAG="collection"
        export NOTICE_TYPE="collections"
        ;;

    'Daily-Export-OD-7-Print')
        export EVENT_DEF=223
        export NOTICE_TAG="7-day-overdue-print"
        export NOTICE_TYPE="overdue"
        export NOTIFY_INTERVAL="7 days"
        export PROCESS_HOOKS="--process-hooks"
        export CUSTOM_FILTERS="--custom-filters $AT_FILTERS/a_t_filters.7_day_od.json"
        ;;
    
    'Daily-Export-OD2-14-Print')
        export EVENT_DEF=224
        export NOTICE_TAG="14-day-second-overdue-print"
        export NOTICE_TYPE="overdue"
        export NOTIFY_INTERVAL="14 days second"
        export PROCESS_HOOKS="--process-hooks"
        export CUSTOM_FILTERS="--custom-filters $AT_FILTERS/a_t_filters.14_day_second_od.json"
        ;;

    'Daily-Export-Hold-Ready-Print')
        export EVENT_DEF=225
        export NOTICE_TAG="holds-available-print"
        export NOTICE_TYPE="hold available"
        ;;

    *)
        echo "No such granularity: '$GRANULARITY'"
        exit 1;
        ;;
esac;

echo "Processing granularity $GRANULARITY"
echo "EVENT_DEF=$EVENT_DEF"
echo "NOTICE_TAG=$NOTICE_TAG"
echo "NOTICE_TYPE=$NOTICE_TYPE"
echo "NOTIFY_INTERVAL=$NOTIFY_INTERVAL"
echo "PROCESS_HOOKS=$PROCESS_HOOKS"
echo "END_DATE=$END_DATE"
echo "FILE_DATE=$FILE_DATE"
echo "WINDOW=$WINDOW"
echo "CUSTOM_FILTERS=$CUSTOM_FILTERS"

echo "Starting: $(date +'%FT%T')"

./process-one-notice.sh

echo "Completed: $(date +'%FT%T')"

