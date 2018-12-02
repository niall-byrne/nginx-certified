#!/usr/bin/env python

import os
import sys
from boto.route53 import *
from time import sleep


def route53_dns(domain, txt_challenge, action='upsert'):

    conn = connection.Route53Connection()

    if 'HOSTED_ZONE' in os.environ:
        hosted_zone = os.environ['HOSTED_ZONE']
        if not domain.endswith(hosted_zone):
            raise Exception("Incorrect hosted zone for domain {0}".format(domain))
        zone = conn.get_hosted_zone_by_name("{0}.".format(hosted_zone))
        zone_id = zone['GetHostedZoneResponse']['HostedZone']['Id'].replace('/hostedzone/', '')
    else:
        zones = conn.get_all_hosted_zones()
        candidate_zones = []
        domain_dot = "{0}.".format(domain)
        for zone in zones['ListHostedZonesResponse']['HostedZones']:
            if domain_dot.endswith(zone['Name']):
                candidate_zones.append((domain_dot.find(zone['Name']), zone['Id'].replace('/hostedzone/', '')))

        if len(candidate_zones) == 0:
            raise Exception("Hosted zone not found for domain {0}".format(domain))

        candidate_zones.sort()
        zone_id = candidate_zones[0][1]

    change_set = record.ResourceRecordSets(conn, zone_id)
    change = change_set.add_change("{0}".format(action.upper()), '_acme-challenge.{0}'.format(domain), type='TXT', ttl=60)
    change.add_value('"{0}"'.format(txt_challenge))
    response = change_set.commit()

    if action.upper() == 'UPSERT':
        # wait for DNS update
        timeout = 300
        sleep_time = 5
        time_elapsed = 0
        st = status.Status(conn, response['ChangeResourceRecordSetsResponse']['ChangeInfo'])
        while st.update() != 'INSYNC' and time_elapsed <= timeout:
            print("Waiting for DNS change to complete... (Elapsed {0} seconds)".format(time_elapsed))
            sleep(sleep_time)
            time_elapsed += sleep_time

        if st.update() != 'INSYNC' and time_elapsed > timeout:
            raise Exception("Timed out while waiting for DNS record to be ready. Waited {0} seconds".format(time_elapsed))

        print("DNS change completed")


if __name__ == "__main__":
    hook = sys.argv[1]

    if hook == "deploy_challenge":
        domain = sys.argv[2]
        txt_challenge = sys.argv[4]
        action = 'upsert'
    elif hook == "clean_challenge":
        domain = sys.argv[2]
        txt_challenge = sys.argv[4]
        action = 'delete'
    elif hook == "startup_hook":
        print("Ignoring startup_hook")
        exit(0)
    elif hook == "exit_hook":
        print("Ignoring exit_hook")
        exit(0)
    elif hook == "deploy_cert":
        print("Ignoring deploy_cert hook")
        exit(0)
    elif hook == "unchanged_cert":
        print("Ignoring unchanged_cert hook")
        exit(0)
    else:
        print("Ignoring unknown hook %s", hook)
        exit(0)

    print("hook: {0}".format(hook))
    print("domain: {0}".format(domain))
    print("txt_challenge: {0}".format(txt_challenge))

    route53_dns(domain, txt_challenge, action)
