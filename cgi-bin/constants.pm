#! /usr/local/bin/perl -w

package constants;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(%countries);
@EXPORT = (@EXPORT, (qw()));

use bigint;
use POSIX qw(log10);
use strict;
no strict 'refs';

our %countries = (
  ''   => '  ',
  'AF' =>  'Afghanistan',
  'AX' =>  'Åland Islands',
  'AL' =>  'Albania',
  'DZ' =>  'Algeria',
  'AS' =>  'American Samoa',
  'AD' =>  'Andorra',
  'AO' =>  'Angola',
  'AI' =>  'Anguilla',
  'AQ' =>  'Antarctica',
  'AG' =>  'Antigua and Barbuda',
  'AR' =>  'Argentina',
  'AM' =>  'Armenia',
  'AW' =>  'Aruba',
  'AU' =>  'Australia',
  'AT' =>  'Austria',
  'AZ' =>  'Azerbaijan',
  'BS' =>  'Bahamas',
  'BH' =>  'Bahrain',
  'BD' =>  'Bangladesh',
  'BB' =>  'Barbados',
  'BY' =>  'Belarus',
  'BE' =>  'Belgium',
  'BZ' =>  'Belize',
  'BJ' =>  'Benin',
  'BM' =>  'Bermuda',
  'BT' =>  'Bhutan',
  'BO' =>  'Bolivia',
  'BA' =>  'Bosnia and Herzegovina',
  'BW' =>  'Botswana',
  'BV' =>  'Bouvet Island',
  'BR' =>  'Brazil',
  'IO' =>  'British Indian Ocean Territory',
  'BN' =>  'Brunei Darussalam',
  'BG' =>  'Bulgaria',
  'BF' =>  'Burkina Faso',
  'BI' =>  'Burundi',
  'KH' =>  'Cambodia',
  'CM' =>  'Cameroon',
  'CA' =>  'Canada',
  'CV' =>  'Cape Verde',
  'KY' =>  'Cayman Islands',
  'CF' =>  'Central African Republic',
  'TD' =>  'Chad',
  'CL' =>  'Chile',
  'CN' =>  'China',
  'CX' =>  'Christmas Island',
  'CC' =>  'Cocos (Keeling) Islands',
  'CO' =>  'Colombia',
  'KM' =>  'Comoros',
  'CG' =>  'Congo',
  'CD' =>  'Congo',
  'CK' =>  'Cook Islands',
  'CR' =>  'Costa Rica',
  'CI' =>  'Côte Divoire',
  'HR' =>  'Croatia',
  'CU' =>  'Cuba',
  'CY' =>  'Cyprus',
  'CZ' =>  'Czech Replublic',
  'DK' =>  'Denmark',
  'DJ' =>  'Djibouti',
  'DM' =>  'Dominica',
  'DO' =>  'Dominican Replublic',
  'EC' =>  'Ecuador',
  'EG' =>  'Egypt',
  'SV' =>  'El Salvador',
  'GQ' =>  'Equatorial Guinea',
  'ER' =>  'Eritrea',
  'EE' =>  'Estonia',
  'ET' =>  'Ethiopia',
  'FK' =>  'Falkland Islands (Malvinas)',
  'FO' =>  'Faroe Islands',
  'FJ' =>  'Fiji',
  'FI' =>  'Finland',
  'FR' =>  'France',
  'GF' =>  'French Guiana',
  'PF' =>  'French Polynesia',
  'TF' =>  'French Southern Territories',
  'GA' =>  'Gabon',
  'GM' =>  'Gambia',
  'GE' =>  'Georgia',
  'DE' =>  'Germany',
  'GH' =>  'Ghana',
  'GI' =>  'Gibraltar',
  'GR' =>  'Greece',
  'GL' =>  'Greenland',
  'GD' =>  'Grenada',
  'GP' =>  'Guadeloupe',
  'GU' =>  'Guam',
  'GT' =>  'Guatemala',
  'GG' =>  'Guernsey',
  'GN' =>  'Guinea',
  'GW' =>  'Guinea-Bissau',
  'GY' =>  'Guyana',
  'HT' =>  'Haiti',
  'HM' =>  'Heard Island and McDonald Islands',
  'VA' =>  'Holy See',
  'HN' =>  'Honduras',
  'HK' =>  'Hong Kong',
  'HU' =>  'Hungary',
  'IS' =>  'Iceland',
  'IN' =>  'India',
  'ID' =>  'Indonesia',
  'IR' =>  'Iran',
  'IQ' =>  'Iraq',
  'IE' =>  'Ireland',
  'IM' =>  'Isle Of Man',
  'IL' =>  'Israel',
  'IT' =>  'Italy',
  'JM' =>  'Jamaica',
  'JP' =>  'Japan',
  'JE' =>  'Jersey',
  'JO' =>  'Jordan',
  'KZ' =>  'Kazakhstan',
  'KE' =>  'Kenya',
  'KI' =>  'Kiribati',
  'KP' =>  'Korea, Democratic Peoples Replublic Of',
  'KR' =>  'Korea',
  'KW' =>  'Kuwait',
  'KG' =>  'Kyrgyzstan',
  'LA' =>  'Lao Peoples Democratic Replublic',
  'LV' =>  'Latvia',
  'LB' =>  'Lebanon',
  'LS' =>  'Lesotho',
  'LR' =>  'Liberia',
  'LY' =>  'Libyan Arab Jamahiriya',
  'LI' =>  'Liechtenstein',
  'LT' =>  'Lithuania',
  'LU' =>  'Luxembourg',
  'MO' =>  'Macao',
  'MK' =>  'Macedonia',
  'MG' =>  'Madagascar',
  'MW' =>  'Malawi',
  'MY' =>  'Malaysia',
  'MV' =>  'Maldives',
  'ML' =>  'Mali',
  'MT' =>  'Malta',
  'MH' =>  'Marshall Islands',
  'MQ' =>  'Martinique',
  'MR' =>  'Mauritania',
  'MU' =>  'Mauritius',
  'YT' =>  'Mayotte',
  'MX' =>  'Mexico',
  'FM' =>  'Micronesia',
  'MD' =>  'Moldova',
  'MC' =>  'Monaco',
  'MN' =>  'Mongolia',
  'ME' =>  'Montenegro',
  'MS' =>  'Montserrat',
  'MA' =>  'Morocco',
  'MZ' =>  'Mozambique',
  'MM' =>  'Myanmar',
  'NA' =>  'Namibia',
  'NR' =>  'Nauru',
  'NP' =>  'Nepal',
  'NL' =>  'Netherlands',
  'AN' =>  'Netherlands Antilles',
  'NC' =>  'New Caledonia',
  'NZ' =>  'New Zealand',
  'NI' =>  'Nicaragua',
  'NE' =>  'Niger',
  'NG' =>  'Nigeria',
  'NU' =>  'Niue',
  'NF' =>  'Norfolk Island',
  'MP' =>  'Northern Mariana Islands',
  'NO' =>  'Norway',
  'OM' =>  'Oman',
  'PK' =>  'Pakistan',
  'PW' =>  'Palau',
  'PS' =>  'Palestinian Territory',
  'PA' =>  'Panama',
  'PG' =>  'Papua New Guinea',
  'PY' =>  'Paraguay',
  'PE' =>  'Peru',
  'PH' =>  'Philippines',
  'PN' =>  'Pitcairn',
  'PL' =>  'Poland',
  'PT' =>  'Portugal',
  'PR' =>  'Puerto Rico',
  'QA' =>  'Qatar',
  'RE' =>  'Réunion',
  'RO' =>  'Romania',
  'RU' =>  'Russian Federation',
  'RW' =>  'Rwanda',
  'BL' =>  'Saint Barthélemy',
  'SH' =>  'Saint Helena, Ascension And Tristan Da Cunha',
  'KN' =>  'Saint Kitts And Nevis',
  'LC' =>  'Saint Lucia',
  'MF' =>  'Saint Martin',
  'PM' =>  'Saint Pierre And Miquelon',
  'VC' =>  'Saint Vincent And The Grenadines',
  'WS' =>  'Samoa',
  'SM' =>  'San Marino',
  'ST' =>  'Sao Tome And Principe',
  'SA' =>  'Saudi Arabia',
  'SN' =>  'Senegal',
  'RS' =>  'Serbia',
  'SC' =>  'Seychelles',
  'SL' =>  'Sierra Leone',
  'SG' =>  'Singapore',
  'SK' =>  'Slovakia',
  'SI' =>  'Slovenia',
  'SB' =>  'Solomon Islands',
  'SO' =>  'Somalia',
  'ZA' =>  'South Africa',
  'GS' =>  'South Georgia And The South Sandwich Islands',
  'ES' =>  'Spain',
  'LK' =>  'Sri Lanka',
  'SD' =>  'Sudan',
  'SR' =>  'Suriname',
  'SJ' =>  'Svalbard And Jan Mayen',
  'SZ' =>  'Swaziland',
  'SE' =>  'Sweden',
  'CH' =>  'Switzerland',
  'SY' =>  'Syrian Arab Replublic',
  'TW' =>  'Taiwan',
  'TJ' =>  'Tajikistan',
  'TZ' =>  'Tanzania',
  'TH' =>  'Thailand',
  'TL' =>  'Timor-Leste',
  'TG' =>  'Togo',
  'TK' =>  'Tokelau',
  'TO' =>  'Tonga',
  'TT' =>  'Trinidad AND Tobago',
  'TN' =>  'Tunisia',
  'TR' =>  'Turkey',
  'TM' =>  'Turkmenistan',
  'TC' =>  'Turks And Caicos Islands',
  'TV' =>  'Tuvalu',
  'UG' =>  'Uganda',
  'UA' =>  'Ukraine',
  'AE' =>  'United Arab Emirates',
  'GB' =>  'United Kingdom',
  'US' =>  'United States',
  'UM' =>  'United States Minor Outlying Islands',
  'UY' =>  'Uruguay',
  'UZ' =>  'Uzbekistan',
  'VU' =>  'Vanuatu',
  'EE' =>  'Vatican City State',
  'VE' =>  'Venezuela',
  'VN' =>  'Viet Nam',
  'VG' =>  'Virgin Islands, British',
  'VI' =>  'Virgin Islands, U.S.',
  'WF' =>  'Wallis And Futuna',
  'EH' =>  'Western Sahara',
  'YE' =>  'Yemen',
  'ZM' =>  'Zambia',
  'ZW' =>  'Zimbabwe',
    );
