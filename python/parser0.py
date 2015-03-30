#! /usr/bin/env python

import mysql.connector
import requests
import sys

from bs4 import BeautifulSoup
from github import Github


def test_github(revstr, revurl):
	print 'test_github({}, {})'.format(revstr, revurl)
	return

def test_sourceforge(revstr, revurl):
	print 'test_sourceforge({}, {})'.format(revstr, revurl)
	return

def test_text(revstr, revurl):
	r = requests.get(revurl)
	revtext = r.text
	if revtext.find(revstr):
		print 'Found {} in {}'.format(revstr, revurl)
	else:
		print 'Did not find {} in {}'.format(revstr, revurl)
	return

try:
	config = {
		'user'    : '_www',
		'password': 'PETimage',
	    'host'    : 'idoimaging.com',
	    'database': 'imaging',
	}
	db = mysql.connector.connect(**config)
except mysql.connector.Error as err:
	print(err)
	exit(1)

query = 'select ident, name, revurl, revstr from program'
query = query + ' where ident >= 100'
if len(sys.argv) > 1:
	query = query + " and name like '" + sys.argv[1] + "%'"
query = query + ' and revurl is not null';
query = query + ' and remdate like \'0000%\'';
query = query + ' order by name';
print(query)

curs = db.cursor()
curs.execute(query)

for (ident, name, revurl, revstr) in curs:
	print '{:4d} {:30s} {:25s} {}'.format(ident, name, revstr, revurl)
	if not len(revurl):
		continue
	if revurl.find('http') < 0:
		revurl = 'http://' + revurl

	if revurl.find('github') >= 0:
		test_github(revstr, revurl)
	elif revurl.find('sourceforge') >= 0:
		test_sourceforge(revstr, revurl)
	else:
		test_text(revstr, revurl)

curs.close()
db.close()
