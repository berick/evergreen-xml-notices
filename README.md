# evergreen-xml-notices

XML Notice File Generator For Evergreen

Generate and send XML files for Evergreen Action/Trigger event definitions.
Files are sent to configured 3rd party for generating print/email/phone/etc. 
notices.

## How-To

### Create an Action/Trigger Event Definition

* Use the **NOOP\_True** reactor.
  * The purpose of the event definition is only to collect target 
    (e.g. circulation ID) information.
* No template is nececessary
* It should **NOT** have a group\_field value.  
  * Grouping is done by the script.
* Give it a unique granularity
* No environment data will be needed, unless one of the other modules
  (e.g. validator) requires it.


#### For Example (Hold Shelf Expire Email)

```sql
    INSERT INTO action_trigger.event_definition (
        id, owner, active, name, hook, validator, reactor, delay, max_delay,
        usr_field, opt_in_setting, delay_field, granularity, retention_interval
    ) VALUES (
        500, 
        1,
        TRUE,
        'Hold Expired On Hold Shelf Email Notice (UMS)',
        'hold_request.cancel.expire_holds_shelf',
        'HoldIsCancelled',
        'NOOP_True',
        '00:00:30',                         -- delay
        NULL,                               -- max delay
        'usr',                              -- usr field
        'notification.hold.cancel.email',   -- opt in
        NULL,                               -- delay field
        'Hold-Shelf-Expire-Email',          -- granularity
        '1 year'
    );
```

### Edit generate-notices.sh

1. Set the required value for the **SCP\_DEST** variable.
1. Comment-out the KCLS notifications configured within the "case $GRANULARITY in" block
 1. Different notice types use different options; the sample notices
    are a useful reference.
1. Add your new notice to the file to the same block
```sh

case $GRANULARITY in

    'Hold-Shelf-Expire-Email')                                                 
        export FOR_EMAIL="--for-email"                                         
        export EVENT_DEF=500
        export NOTICE_TAG=hold-shelf-expire                                    
        export NOTICE_TYPE="hold shelf expire email"                           
        ;; 

esac

```
1. Create the XML file output directory
```sh
sudo -u opensrf mkdir -p /openils/var/data/xml-notices
```

### Generate and Send the XML File

#### Example 1

```sh
./generate-notices.sh --granularity Hold-Shelf-Expire-Email
```

#### Example 2

By default, the script processes events whose run\_time occurred yesterday,
but this can be modified via the **--end-date** and **--window** variables.

```sh
./generate-notices.sh --send-xml --window "1 hour" \
    --end-date "$(date +'%FT%H:00:00')" --granularity Hold-Ready-Locker-Phone
```



