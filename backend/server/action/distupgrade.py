# -*- coding: utf-8 -*-
#
# Copyright (c) 2012 Novell
#
# This software is licensed to you under the GNU General Public License,
# version 2 (GPLv2). There is NO WARRANTY for this software, express or
# implied, including the implied warranties of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
# along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
#

import sys
from spacewalk.common.rhnLog import log_debug
from spacewalk.common.rhnException import rhnFault
from spacewalk.server import rhnSQL
from spacewalk.server.rhnChannel import subscribe_channels, unsubscribe_channels
from spacewalk.server.rhnLib import InvalidAction

# the "exposed" functions
__rhnexport__ = ['upgrade']

_query_dup_data = rhnSQL.Statement("""
    SELECT id, dry_run, full_update
      FROM rhnActionDup
     WHERE action_id = :action_id
""")

_query_channel_changes = rhnSQL.Statement("""
    SELECT c.id, c.label, c.parent_channel, adc.task
      FROM rhnActionDupChannel adc
      JOIN rhnChannel c ON adc.channel_id = c.id
     WHERE adc.action_dup_id = :action_dup_id
""")

_query_products = rhnSQL.Statement("""
    SELECT p1.name,
           p1.version,
           p2.name new_name,
           p2.version new_version,
           COALESCE(p2.release, ' ') new_release,
           COALESCE(pa.label, ' ') new_arch
      FROM rhnActionDupProduct adp
      JOIN suseProducts p1 ON adp.from_pdid = p1.id
      JOIN suseProducts p2 ON adp.to_pdid = p2.id
 LEFT JOIN rhnPackageArch pa ON pa.id = p2.arch_type_id
     WHERE adp.action_dup_id = :action_dup_id
""")


# returns the values required to execute a dist upgrade
# change also the channel subscription
#
def upgrade(serverId, actionId, dry_run=0):
    log_debug(3)

    h = rhnSQL.prepare(_query_dup_data)
    h.execute(action_id=actionId)
    row = h.fetchone_dict()
    if not row:
        # No dup for this action
        raise InvalidAction("distupgrade.upgrade: No action found for action id "
            "%s and server %s" % (actionId, serverId))

    action_dup_id = row['id']

    # get product info

    h = rhnSQL.prepare(_query_products)
    h.execute(action_dup_id=action_dup_id)
    products = h.fetchall_dict() or []

    # only SLE10 products needs to be changed manually
    # remove all not SLE10 based products

    sle10_products = []
    do_change = False
    for product in products:
        if product['version'] == '10':
            do_change = True
            sle10_products.append(product)

    # switch the channels for this server

    h = rhnSQL.prepare(_query_channel_changes)
    h.execute(action_dup_id=action_dup_id)
    channel_changes = h.fetchall_dict() or None

    if not channel_changes:
        # this happens in case a distupgrade failed and the
        # another distupgrade is scheduled to fix the installation
        # we do not have the original channels anymore, so we need
        # to execute a full "dup" without channels
        params = {
            "full_update"         : (row['full_update'] == 'Y'),
            "change_product"      : do_change,
            "products"            : sle10_products,
            "dry_run"             : (row['dry_run'] == 'Y') }
        return (params)

    to_subscribe = filter(lambda x: x['task'] == 'S', channel_changes)
    to_unsubscribe = filter(lambda x: x['task'] == 'U', channel_changes)

    try:
        unsubscribe_channels(serverId, to_unsubscribe)
        subscribe_channels(serverId, to_subscribe)
    except rhnFault, f:
        if f.code == 38:
            # channel is already subscribed, ignore it
            pass
        else:
            raise InvalidAction(str(e)), None, sys.exc_info()[2]
    except Exception, e:
        raise InvalidAction(str(e)), None, sys.exc_info()[2]

    rhnSQL.commit()

    params = {
        "dup_channel_names"   : map(lambda x: x['label'], to_subscribe),
        "full_update"         : (row['full_update'] == 'Y'),
        "change_product"      : do_change,
        "products"            : sle10_products,
        "dry_run"             : (row['dry_run'] == 'Y') }
    return (params)

