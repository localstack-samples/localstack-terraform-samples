#!/usr/bin/env sh

set -x

tflocal init; tflocal plan; tflocal apply --auto-approve

ws_endpoint=$(tflocal output -json | jq -r .ws_endpoint.value)

wscat -c 127.0.0.1:4510

# {"deviceTimestamp":"2023-02-27 14:02:17.690406","deviceID":"1","recordingID":"9ad513cb-2d14-4b52-b4f8-bad9181a649d01","payload":"8Dm/iP8AKReRDQqDP/OvXERjyXCJMqx0rbndWKbFdcCRGIyALPPSTs2YNzJARf6UjyNF/Ah0/SiEupi42QefsBPWR65myxsXGR0g6SS8TYPrLhveRzJbDQs+DlfGB4J9Ar923Efz99kbr4Jb87eaMdCA6W9irWBdQPh65YnfeT+FNfFmw72VT99sSRMPhUc8/Oxld6J2MpsqoVfh8c45Ut3osBGPI12J6dY4Y6clDw==","stop":false,"recorded":false}
