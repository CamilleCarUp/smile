import '../models/request.dart';

/// Die kantonalen Ombudsstellen (Begutachtungskommissionen) der SSO.
///
/// Unvollstaendig: Fuer Nidwalden, Obwalden und Uri ist keine eigene Stelle
/// bekannt. Betroffene sehen deshalb die vollstaendige Liste statt eines
/// falschen Treffers.
const List<OmbudsmanContact> ombudsmanContacts = [
  OmbudsmanContact(region: 'Aargau', name: 'Frau Regula Hunziker', location: '5734 Reinach', phone: '+41 62 771 64 00', cantons: const ['AG']),
  OmbudsmanContact(region: 'Basel-Landschaft', name: 'Dr. med. dent. Urs Röthlisberger', location: '4410 Liestal', phone: '+41 61 921 67 91', cantons: const ['BL']),
  OmbudsmanContact(region: 'Basel-Stadt', name: 'Frau Stefanie Frey', location: '4054 Basel', phone: '+41 61 312 02 81', cantons: const ['BS']),
  OmbudsmanContact(region: 'Bern', name: 'Dr. iur. Lorenz Hirt', location: '3000 Bern', phone: '+41 31 351 82 10', cantons: const ['BE']),
  OmbudsmanContact(region: 'Fribourg', name: 'Dr. méd. dent. Jean-Pierre Parisod', location: '1630 Bulle', phone: '+41 26 912 03 03', cantons: const ['FR']),
  OmbudsmanContact(region: 'Genève', name: 'Mme Tanya Walliser', location: '1211 Genève', phone: '+41 58 715 32 25', cantons: const ['GE']),
  OmbudsmanContact(region: 'Glarus', name: 'lic. iur. Sylvia Nafz', location: '8027 Zürich', phone: '+41 43 344 92 33', cantons: const ['GL']),
  OmbudsmanContact(region: 'Graubünden', name: 'Dr. iur. Raphaela Holliger', location: '7001 Chur', phone: '+41 81 252 26 82', cantons: const ['GR']),
  OmbudsmanContact(region: 'Jura', name: 'Méd. dent. Pierre-Yves Stampbach', location: '2800 Delémont', phone: '+41 32 423 36 38', cantons: const ['JU']),
  OmbudsmanContact(region: 'Luzern', name: 'Dr. med. dent., Dr. med. Stefan Hug', location: '6010 Kriens', phone: '+41 41 320 45 18', cantons: const ['LU']),
  OmbudsmanContact(region: 'Neuchâtel', name: 'Méd. dent. Marc-André Kaufmann', location: '2035 Corcelles', phone: '+41 32 731 23 55', cantons: const ['NE']),
  OmbudsmanContact(region: 'Schaffhausen', name: 'Frau Daniela Kaufmann', location: '8234 Stettlen', phone: '+41 52 643 23 31', cantons: const ['SH']),
  OmbudsmanContact(region: 'Schwyz', name: 'Miriam Landolt-Kistler', location: '6438 Ibach/SZ', phone: '+41 79 609 94 90', cantons: const ['SZ']),
  OmbudsmanContact(region: 'Solothurn', name: 'lic. iur. Beat Muralt', location: '4500 Solothurn', phone: '+41 32 622 40 10', cantons: const ['SO']),
  OmbudsmanContact(region: 'St. Gallen & Appenzell (AR+AI)', name: 'Frau Sandra Quidiello', location: '9016 St. Gallen', phone: '+41 71 242 09 90', cantons: const ['SG', 'AR', 'AI']),
  OmbudsmanContact(region: 'Thurgau', name: 'Dr. med. dent. Thomas Hitz', location: 'Weinfelden', phone: '+41 71 622 44 77', cantons: const ['TG']),
  OmbudsmanContact(region: 'Ticino', name: 'Med. dent. Reto Reali', location: '6500 Bellinzona', phone: '+41 91 825 81 35', cantons: const ['TI']),
  OmbudsmanContact(region: 'Valais', name: 'Dr. méd. dent. Jean-Marc Zurcher', location: '1920 Martigny', phone: '+41 27 722 20 01', cantons: const ['VS']),
  OmbudsmanContact(region: 'Vaud', name: 'Dr. méd. dent. Philippe Hediger', location: '1807 Blonay', phone: '+41 21 946 18 84', cantons: const ['VD']),
  OmbudsmanContact(region: 'Zug', name: 'Dr. med. dent. Urs Zellweger', location: '6300 Zug', phone: '+41 41 726 20 30', cantons: const ['ZG']),
  OmbudsmanContact(region: 'Zürich', name: 'lic. iur. Sylvia Nafz', location: '8027 Zürich', phone: '+41 43 344 92 33', cantons: const ['ZH']),
];
