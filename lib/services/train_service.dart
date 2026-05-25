import 'dart:math' as math;
import '../models/train.dart';

class TrainService {
  static final TrainService _instance = TrainService._internal();
  factory TrainService() => _instance;
  TrainService._internal();

  final List<Train> _allTrains = [
    // ── Vande Bharat ─────────────────────────────────────────────────────────
    Train(number: "22436", name: "NDLS - BSB VANDE BHARAT EXP", source: "New Delhi (NDLS)", destination: "Varanasi (BSB)", departureTime: "06:00", arrivalTime: "14:00", duration: "08h 00m", classes: ["CC", "EC"], prices: {"CC": 1750.0, "EC": 3200.0}, availability: {"CC": 45, "EC": 12}, type: "Vande Bharat"),
    Train(number: "20901", name: "MMCT - GNC VANDE BHARAT EXP", source: "Mumbai Central (MMCT)", destination: "Gandhinagar Cap (GNC)", departureTime: "06:10", arrivalTime: "12:25", duration: "06h 15m", classes: ["CC", "EC"], prices: {"CC": 1420.0, "EC": 2630.0}, availability: {"CC": 120, "EC": 18}, type: "Vande Bharat"),
    Train(number: "22301", name: "HWH - NJP VANDE BHARAT EXP", source: "Howrah (HWH)", destination: "New Jalpaiguri (NJP)", departureTime: "05:55", arrivalTime: "13:35", duration: "07h 40m", classes: ["CC", "EC"], prices: {"CC": 1565.0, "EC": 2825.0}, availability: {"CC": -5, "EC": 3}, type: "Vande Bharat"),
    Train(number: "20601", name: "CHENNAI VANDE BHARAT EXP", source: "Chennai Central (MAS)", destination: "Mysuru Jn (MYS)", departureTime: "06:00", arrivalTime: "11:00", duration: "05h 00m", classes: ["CC", "EC"], prices: {"CC": 1200.0, "EC": 2350.0}, availability: {"CC": 60, "EC": 22}, type: "Vande Bharat"),
    Train(number: "22549", name: "SC - VSKP VANDE BHARAT EXP", source: "Secunderabad Jn (SC)", destination: "Visakhapatnam (VSKP)", departureTime: "05:50", arrivalTime: "13:25", duration: "07h 35m", classes: ["CC", "EC"], prices: {"CC": 1580.0, "EC": 2950.0}, availability: {"CC": 35, "EC": 8}, type: "Vande Bharat"),
    Train(number: "22454", name: "MDU - MAS VANDE BHARAT EXP", source: "Madurai Jn (MDU)", destination: "Chennai Central (MAS)", departureTime: "05:25", arrivalTime: "13:00", duration: "07h 35m", classes: ["CC", "EC"], prices: {"CC": 1280.0, "EC": 2450.0}, availability: {"CC": 42, "EC": 15}, type: "Vande Bharat"),
    Train(number: "22691", name: "SBC VANDE BHARAT EXP", source: "KSR Bengaluru (SBC)", destination: "Chennai Central (MAS)", departureTime: "05:50", arrivalTime: "11:00", duration: "05h 10m", classes: ["CC", "EC"], prices: {"CC": 1150.0, "EC": 2200.0}, availability: {"CC": 55, "EC": 18}, type: "Vande Bharat"),

    // ── Rajdhani Express ───────────────────────────────────────────────────────
    Train(number: "12302", name: "HWH RAJDHANI EXPRESS", source: "New Delhi (NDLS)", destination: "Howrah (HWH)", departureTime: "16:50", arrivalTime: "09:55", duration: "17h 05m", classes: ["1A", "2A", "3A"], prices: {"1A": 4390.0, "2A": 2850.0, "3A": 2100.0}, availability: {"1A": 4, "2A": 19, "3A": 42}, type: "Rajdhani"),
    Train(number: "12952", name: "MUMBAI RAJDHANI", source: "New Delhi (NDLS)", destination: "Mumbai Central (MMCT)", departureTime: "16:55", arrivalTime: "08:35", duration: "15h 40m", classes: ["1A", "2A", "3A"], prices: {"1A": 4260.0, "2A": 2720.0, "3A": 1980.0}, availability: {"1A": 2, "2A": -8, "3A": 65}, type: "Rajdhani"),
    Train(number: "12432", name: "TRIVANDRAM RAJDHANI", source: "Hazrat Nizamuddin (NZM)", destination: "Thiruvananthapuram (TVC)", departureTime: "06:10", arrivalTime: "23:45", duration: "41h 35m", classes: ["1A", "2A", "3A"], prices: {"1A": 7250.0, "2A": 4820.0, "3A": 3480.0}, availability: {"1A": 0, "2A": 4, "3A": -12}, type: "Rajdhani"),
    Train(number: "12424", name: "DIBRUGARH RAJDHANI", source: "New Delhi (NDLS)", destination: "Dibrugarh (DBRG)", departureTime: "20:00", arrivalTime: "06:30", duration: "34h 30m", classes: ["1A", "2A", "3A"], prices: {"1A": 6480.0, "2A": 4100.0, "3A": 3020.0}, availability: {"1A": 6, "2A": 22, "3A": 56}, type: "Rajdhani"),
    Train(number: "12442", name: "BILASPUR RAJDHANI", source: "New Delhi (NDLS)", destination: "Bilaspur Jn (BSP)", departureTime: "22:30", arrivalTime: "22:30", duration: "24h 00m", classes: ["1A", "2A", "3A"], prices: {"1A": 4980.0, "2A": 3250.0, "3A": 2420.0}, availability: {"1A": 1, "2A": 11, "3A": 38}, type: "Rajdhani"),
    Train(number: "12453", name: "RANCHI RAJDHANI", source: "New Delhi (NDLS)", destination: "Ranchi (RNC)", departureTime: "17:00", arrivalTime: "13:45", duration: "20h 45m", classes: ["1A", "2A", "3A"], prices: {"1A": 4950.0, "2A": 3180.0, "3A": 2350.0}, availability: {"1A": 5, "2A": 20, "3A": 48}, type: "Rajdhani"),
    Train(number: "22692", name: "RAJDHANI EXPRESS", source: "New Delhi (NDLS)", destination: "KSR Bengaluru (SBC)", departureTime: "20:15", arrivalTime: "05:20", duration: "33h 05m", classes: ["1A", "2A", "3A"], prices: {"1A": 6350.0, "2A": 4050.0, "3A": 2980.0}, availability: {"1A": 3, "2A": 14, "3A": 44}, type: "Rajdhani"),
    Train(number: "12985", name: "JAIPUR RAJDHANI", source: "New Delhi (NDLS)", destination: "Jaipur Jn (JP)", departureTime: "17:55", arrivalTime: "21:55", duration: "04h 00m", classes: ["1A", "2A", "3A", "CC"], prices: {"1A": 2450.0, "2A": 1580.0, "3A": 1160.0, "CC": 1050.0}, availability: {"1A": 8, "2A": 30, "3A": 82, "CC": 60}, type: "Rajdhani"),
    Train(number: "12245", name: "HWH - YPR DURONTO EXP", source: "Howrah (HWH)", destination: "Yesvantpur Jn (YPR)", departureTime: "19:10", arrivalTime: "06:05", duration: "34h 55m", classes: ["1A", "2A", "3A"], prices: {"1A": 5680.0, "2A": 3580.0, "3A": 2620.0}, availability: {"1A": 4, "2A": 12, "3A": 40}, type: "Rajdhani"),

    // ── Shatabdi Express ───────────────────────────────────────────────────────
    Train(number: "12002", name: "NDLS - BPL SHATABDI EXP", source: "New Delhi (NDLS)", destination: "Bhopal Jn (BPL)", departureTime: "06:00", arrivalTime: "14:40", duration: "08h 40m", classes: ["CC", "EC"], prices: {"CC": 1150.0, "EC": 2240.0}, availability: {"CC": 88, "EC": 14}, type: "Shatabdi"),
    Train(number: "12004", name: "NDLS - LKO SHATABDI EXP", source: "New Delhi (NDLS)", destination: "Lucknow Charbagh (LKO)", departureTime: "06:10", arrivalTime: "12:40", duration: "06h 30m", classes: ["CC", "EC"], prices: {"CC": 1080.0, "EC": 2110.0}, availability: {"CC": 25, "EC": -2}, type: "Shatabdi"),
    Train(number: "12014", name: "AMRITSAR SHATABDI EXP", source: "New Delhi (NDLS)", destination: "Amritsar Jn (ASR)", departureTime: "07:20", arrivalTime: "13:15", duration: "05h 55m", classes: ["CC", "EC"], prices: {"CC": 980.0, "EC": 1900.0}, availability: {"CC": 72, "EC": 10}, type: "Shatabdi"),
    Train(number: "12030", name: "SWARNA SHATABDI EXP", source: "New Delhi (NDLS)", destination: "Amritsar Jn (ASR)", departureTime: "19:30", arrivalTime: "23:50", duration: "04h 20m", classes: ["CC", "EC", "2S"], prices: {"CC": 840.0, "EC": 1650.0, "2S": 340.0}, availability: {"CC": 48, "EC": 6, "2S": 120}, type: "Shatabdi"),

    // ── Express Trains ─────────────────────────────────────────────────────────
    Train(number: "12626", name: "KERALA EXPRESS", source: "New Delhi (NDLS)", destination: "Thiruvananthapuram (TVC)", departureTime: "20:10", arrivalTime: "14:15", duration: "42h 05m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 3200.0, "3A": 2200.0, "SL": 880.0, "GN": 350.0}, availability: {"2A": 15, "3A": 55, "SL": 140, "GN": 400}, type: "Express"),
    Train(number: "12802", name: "PURUSHOTTAM EXP", source: "New Delhi (NDLS)", destination: "Puri (PURI)", departureTime: "22:40", arrivalTime: "05:25", duration: "30h 45m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 2680.0, "3A": 1850.0, "SL": 710.0, "GN": 280.0}, availability: {"2A": 8, "3A": -20, "SL": 98, "GN": 350}, type: "Express"),
    Train(number: "12615", name: "GRAND TRUNK EXPRESS", source: "New Delhi (NDLS)", destination: "Chennai Central (MAS)", departureTime: "18:35", arrivalTime: "17:35", duration: "23h 00m", classes: ["1A", "2A", "3A", "SL", "GN"], prices: {"1A": 5800.0, "2A": 3650.0, "3A": 2550.0, "SL": 980.0, "GN": 380.0}, availability: {"1A": 3, "2A": 18, "3A": 72, "SL": 220, "GN": 500}, type: "Express"),
    Train(number: "12318", name: "AKAL TAKHT EXPRESS", source: "Amritsar Jn (ASR)", destination: "Howrah (HWH)", departureTime: "17:35", arrivalTime: "22:10", duration: "28h 35m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 2750.0, "3A": 1890.0, "SL": 720.0, "GN": 290.0}, availability: {"2A": 12, "3A": 44, "SL": 128, "GN": 320}, type: "Express"),
    Train(number: "12792", name: "SECUNDERABAD EXP", source: "New Delhi (NDLS)", destination: "Secunderabad Jn (SC)", departureTime: "06:35", arrivalTime: "09:35", duration: "27h 00m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 2900.0, "3A": 1980.0, "SL": 770.0, "GN": 300.0}, availability: {"2A": 20, "3A": 58, "SL": 150, "GN": 400}, type: "Express"),
    Train(number: "12724", name: "TELANGANA EXPRESS", source: "New Delhi (NDLS)", destination: "Secunderabad Jn (SC)", departureTime: "14:30", arrivalTime: "17:45", duration: "27h 15m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 2880.0, "3A": 1970.0, "SL": 760.0, "GN": 300.0}, availability: {"2A": 16, "3A": 50, "SL": 160, "GN": 420}, type: "Express"),
    Train(number: "12910", name: "GARIB RATH EXPRESS", source: "Mumbai Central (MMCT)", destination: "Patna Jn (PNBE)", departureTime: "18:10", arrivalTime: "05:10", duration: "35h 00m", classes: ["3A", "SL"], prices: {"3A": 1320.0, "SL": 520.0}, availability: {"3A": 35, "SL": 95}, type: "Express"),
    Train(number: "12648", name: "KONGU EXPRESS", source: "Chennai Central (MAS)", destination: "Coimbatore Jn (CBE)", departureTime: "21:45", arrivalTime: "04:30", duration: "06h 45m", classes: ["2A", "3A", "SL", "2S", "GN"], prices: {"2A": 1280.0, "3A": 880.0, "SL": 340.0, "2S": 210.0, "GN": 120.0}, availability: {"2A": 22, "3A": 68, "SL": 190, "2S": 80, "GN": 200}, type: "Express"),
    Train(number: "12163", name: "DADAR - MAS SUPERFAST", source: "Chhatrapati Shivaji Terminus (CSMT)", destination: "Chennai Central (MAS)", departureTime: "23:50", arrivalTime: "05:00", duration: "29h 10m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 2550.0, "3A": 1760.0, "SL": 680.0, "GN": 270.0}, availability: {"2A": 10, "3A": 42, "SL": 120, "GN": 350}, type: "Express"),
    Train(number: "12650", name: "YERCAUD EXPRESS", source: "KSR Bengaluru (SBC)", destination: "Chennai Central (MAS)", departureTime: "22:00", arrivalTime: "05:00", duration: "07h 00m", classes: ["2A", "3A", "SL", "2S"], prices: {"2A": 920.0, "3A": 640.0, "SL": 250.0, "2S": 160.0}, availability: {"2A": 30, "3A": 82, "SL": 200, "2S": 60}, type: "Express"),
    Train(number: "12840", name: "HOWRAH MAIL", source: "Howrah (HWH)", destination: "Chennai Central (MAS)", departureTime: "21:40", arrivalTime: "04:45", duration: "31h 05m", classes: ["1A", "2A", "3A", "SL", "GN"], prices: {"1A": 4880.0, "2A": 3050.0, "3A": 2120.0, "SL": 820.0, "GN": 320.0}, availability: {"1A": 2, "2A": 14, "3A": 55, "SL": 162, "GN": 420}, type: "Express"),
    Train(number: "12654", name: "NIZAMUDDIN EXP", source: "Hazrat Nizamuddin (NZM)", destination: "KSR Bengaluru (SBC)", departureTime: "09:45", arrivalTime: "18:15", duration: "32h 30m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 3100.0, "3A": 2140.0, "SL": 840.0, "GN": 330.0}, availability: {"2A": 18, "3A": 60, "SL": 175, "GN": 460}, type: "Express"),
    Train(number: "16032", name: "ANDAMAN EXPRESS", source: "Chennai Central (MAS)", destination: "Madurai Jn (MDU)", departureTime: "21:15", arrivalTime: "05:00", duration: "07h 45m", classes: ["3A", "SL", "2S", "GN"], prices: {"3A": 640.0, "SL": 250.0, "2S": 140.0, "GN": 90.0}, availability: {"3A": 44, "SL": 130, "2S": 65, "GN": 250}, type: "Express"),
    Train(number: "19019", name: "DEHRADUN EXPRESS", source: "Mumbai Central (MMCT)", destination: "Patna Jn (PNBE)", departureTime: "21:50", arrivalTime: "07:05", duration: "33h 15m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 2400.0, "3A": 1650.0, "SL": 640.0, "GN": 250.0}, availability: {"2A": 9, "3A": 38, "SL": 112, "GN": 310}, type: "Express"),
    Train(number: "12903", name: "GOLDEN TEMPLE MAIL", source: "Mumbai Central (MMCT)", destination: "Amritsar Jn (ASR)", departureTime: "21:35", arrivalTime: "06:35", duration: "33h 00m", classes: ["1A", "2A", "3A", "SL", "GN"], prices: {"1A": 5200.0, "2A": 3320.0, "3A": 2300.0, "SL": 890.0, "GN": 355.0}, availability: {"1A": 3, "2A": 16, "3A": 62, "SL": 185, "GN": 480}, type: "Express"),
    Train(number: "18188", name: "TATA - PRYJ EXPRESS", source: "Tatanagar Jn (TATA)", destination: "Prayagraj (PRYJ)", departureTime: "15:35", arrivalTime: "04:10", duration: "12h 35m", classes: ["SL", "2S", "GN"], prices: {"SL": 310.0, "2S": 195.0, "GN": 95.0}, availability: {"SL": 88, "2S": 45, "GN": 180}, type: "Express"),
    Train(number: "22120", name: "CSMT - PUNE INTERCITY", source: "Chhatrapati Shivaji Terminus (CSMT)", destination: "Pune Jn (PUNE)", departureTime: "06:55", arrivalTime: "10:05", duration: "03h 10m", classes: ["CC", "2S", "GN"], prices: {"CC": 620.0, "2S": 260.0, "GN": 110.0}, availability: {"CC": 55, "2S": 120, "GN": 400}, type: "Express"),
    Train(number: "16209", name: "AJMER EXPRESS", source: "Mysuru Jn (MYS)", destination: "Ajmer Jn (AII)", departureTime: "13:10", arrivalTime: "06:30", duration: "41h 20m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 2850.0, "3A": 1960.0, "SL": 760.0, "GN": 300.0}, availability: {"2A": 7, "3A": 35, "SL": 95, "GN": 270}, type: "Express"),
    Train(number: "12461", name: "MANDOR EXPRESS", source: "New Delhi (NDLS)", destination: "Jodhpur Jn (JU)", departureTime: "23:40", arrivalTime: "09:50", duration: "10h 10m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 1680.0, "3A": 1150.0, "SL": 445.0, "GN": 175.0}, availability: {"2A": 16, "3A": 52, "SL": 148, "GN": 380}, type: "Express"),
    Train(number: "12478", name: "JAT - CDG EXPRESS", source: "Jammu Tawi (JAT)", destination: "Chandigarh (CDG)", departureTime: "08:20", arrivalTime: "14:50", duration: "06h 30m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 980.0, "3A": 680.0, "SL": 260.0, "GN": 105.0}, availability: {"2A": 20, "3A": 65, "SL": 180, "GN": 450}, type: "Express"),
    Train(number: "12558", name: "SAPT KRANTI EXPRESS", source: "New Delhi (NDLS)", destination: "Patna Jn (PNBE)", departureTime: "21:05", arrivalTime: "09:55", duration: "12h 50m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 1750.0, "3A": 1210.0, "SL": 465.0, "GN": 185.0}, availability: {"2A": 18, "3A": 56, "SL": 168, "GN": 440}, type: "Express"),
    Train(number: "12393", name: "SAMPOORNA KRANTI EXP", source: "New Delhi (NDLS)", destination: "Patna Jn (PNBE)", departureTime: "23:55", arrivalTime: "12:40", duration: "12h 45m", classes: ["1A", "2A", "3A", "SL", "GN"], prices: {"1A": 3280.0, "2A": 2100.0, "3A": 1460.0, "SL": 560.0, "GN": 225.0}, availability: {"1A": 5, "2A": 22, "3A": 65, "SL": 190, "GN": 500}, type: "Express"),
    Train(number: "12188", name: "GARIB NAWAZ SF EXP", source: "New Delhi (NDLS)", destination: "Ajmer Jn (AII)", departureTime: "15:10", arrivalTime: "22:55", duration: "07h 45m", classes: ["2A", "3A", "SL", "2S", "GN"], prices: {"2A": 1220.0, "3A": 840.0, "SL": 325.0, "2S": 205.0, "GN": 120.0}, availability: {"2A": 14, "3A": 48, "SL": 132, "2S": 58, "GN": 300}, type: "Express"),
    Train(number: "16594", name: "HAMPI EXPRESS", source: "Yesvantpur Jn (YPR)", destination: "Hubli Jn (UBL)", departureTime: "22:45", arrivalTime: "05:55", duration: "07h 10m", classes: ["SL", "2S", "GN"], prices: {"SL": 280.0, "2S": 175.0, "GN": 85.0}, availability: {"SL": 110, "2S": 50, "GN": 200}, type: "Express"),
    Train(number: "11302", name: "UDYAN EXPRESS", source: "Chhatrapati Shivaji Terminus (CSMT)", destination: "KSR Bengaluru (SBC)", departureTime: "08:05", arrivalTime: "02:30", duration: "18h 25m", classes: ["FC", "2A", "3A", "SL", "GN"], prices: {"FC": 3100.0, "2A": 2180.0, "3A": 1520.0, "SL": 590.0, "GN": 235.0}, availability: {"FC": 4, "2A": 18, "3A": 60, "SL": 165, "GN": 420}, type: "Express"),
    Train(number: "12238", name: "BEGAMPURA EXPRESS", source: "Mumbai Central (MMCT)", destination: "Patna Jn (PNBE)", departureTime: "23:35", arrivalTime: "05:55", duration: "30h 20m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 2980.0, "3A": 2050.0, "SL": 780.0, "GN": 315.0}, availability: {"2A": 14, "3A": 62, "SL": 180, "GN": 450}, type: "Express"),
    Train(number: "12141", name: "LTT - PATLIPUTRA EXP", source: "Lokmanya Tilak Terminus (LTT)", destination: "Patna Jn (PNBE)", departureTime: "00:45", arrivalTime: "07:20", duration: "30h 35m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 2680.0, "3A": 1840.0, "SL": 700.0, "GN": 280.0}, availability: {"2A": 10, "3A": 44, "SL": 140, "GN": 380}, type: "Express"),
    Train(number: "12025", name: "PUNJ MAIL", source: "Howrah (HWH)", destination: "Amritsar Jn (ASR)", departureTime: "20:00", arrivalTime: "05:30", duration: "33h 30m", classes: ["1A", "2A", "3A", "SL", "GN"], prices: {"1A": 5100.0, "2A": 3280.0, "3A": 2280.0, "SL": 880.0, "GN": 350.0}, availability: {"1A": 3, "2A": 15, "3A": 58, "SL": 175, "GN": 460}, type: "Express"),
    Train(number: "12027", name: "KLK SHATABDI EXP", source: "New Delhi (NDLS)", destination: "Chandigarh (CDG)", departureTime: "07:40", arrivalTime: "10:35", duration: "02h 55m", classes: ["CC", "EC", "2S"], prices: {"CC": 720.0, "EC": 1420.0, "2S": 285.0}, availability: {"CC": 85, "EC": 20, "2S": 160}, type: "Shatabdi"),
    Train(number: "12473", name: "SARVODAYA EXPRESS", source: "New Delhi (NDLS)", destination: "Jammu Tawi (JAT)", departureTime: "21:30", arrivalTime: "07:45", duration: "10h 15m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 1520.0, "3A": 1050.0, "SL": 405.0, "GN": 160.0}, availability: {"2A": 22, "3A": 68, "SL": 192, "GN": 500}, type: "Express"),
    Train(number: "12969", name: "JAIPUR SF EXPRESS", source: "Patna Jn (PNBE)", destination: "Jaipur Jn (JP)", departureTime: "06:00", arrivalTime: "06:30", duration: "24h 30m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 2200.0, "3A": 1520.0, "SL": 590.0, "GN": 235.0}, availability: {"2A": 16, "3A": 50, "SL": 155, "GN": 410}, type: "Express"),
    Train(number: "12644", name: "THIRUKKURAL EXP", source: "Patna Jn (PNBE)", destination: "Chennai Central (MAS)", departureTime: "12:55", arrivalTime: "09:00", duration: "44h 05m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 3450.0, "3A": 2380.0, "SL": 920.0, "GN": 365.0}, availability: {"2A": 8, "3A": 38, "SL": 112, "GN": 300}, type: "Express"),
    Train(number: "12204", name: "SHALIMAR EXPRESS", source: "Howrah (HWH)", destination: "Secunderabad Jn (SC)", departureTime: "14:05", arrivalTime: "16:10", duration: "26h 05m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 2750.0, "3A": 1890.0, "SL": 730.0, "GN": 290.0}, availability: {"2A": 12, "3A": 46, "SL": 138, "GN": 360}, type: "Express"),
    Train(number: "22847", name: "VISAKHAPATNAM EXP", source: "Howrah (HWH)", destination: "Visakhapatnam (VSKP)", departureTime: "11:50", arrivalTime: "05:25", duration: "17h 35m", classes: ["2A", "3A", "SL", "GN"], prices: {"2A": 2100.0, "3A": 1440.0, "SL": 555.0, "GN": 220.0}, availability: {"2A": 18, "3A": 60, "SL": 170, "GN": 450}, type: "Express"),
  ];

  // Helper to fetch route stations (stops) for a train
  List<String> getRouteStations(Train t) {
    if (t.number == "22436") {
      return ["New Delhi (NDLS)", "Kanpur Central (CNB)", "Prayagraj Jn (PRYJ)", "Varanasi (BSB)"];
    } else if (t.number == "12302") {
      return ["New Delhi (NDLS)", "Kanpur Central (CNB)", "Prayagraj Jn (PRYJ)", "Pt DD Upadhyaya (DDU)", "Gaya Jn (GAYA)", "Dhanbad Jn (DHN)", "Asansol Jn (ASN)", "Howrah (HWH)"];
    }
    
    // Fallback/dynamic: generate route from the corridor matching its number
    final int numVal = int.tryParse(t.number) ?? 12345;
    final int corridorIdx = numVal % 5;
    final List<Map<String, dynamic>> stationsData = _corridors[corridorIdx];
    
    final List<String> route = [t.source];
    for (int i = 1; i < stationsData.length - 1; i++) {
      final name = stationsData[i]["name"].toString();
      if (name != t.source && name != t.destination) {
        route.add(name);
      }
    }
    if (!route.contains(t.destination)) {
      route.add(t.destination);
    }
    return route;
  }

  bool runsOnDate(Train t, DateTime date) {
    final int weekday = date.weekday;
    if (t.type == "Vande Bharat") {
      return weekday != 4; // Not Thursday
    } else if (t.type == "Rajdhani") {
      return weekday == 1 || weekday == 3 || weekday == 5 || weekday == 7; // Mon, Wed, Fri, Sun
    } else if (t.type == "Shatabdi") {
      return weekday == 2 || weekday == 4 || weekday == 6; // Tue, Thu, Sat
    }
    return true; // Express runs daily
  }

  // ── Improved search: matches by station name, code, or partial text ─────────
  List<Train> searchTrains(String source, String destination, DateTime date) {
    if (source.trim().isEmpty || destination.trim().isEmpty) return [];

    // Extract station code from "(CODE)" format
    String extractCode(String s) {
      final m = RegExp(r'\((\w+)\)').firstMatch(s);
      return m != null ? m.group(1)!.toLowerCase() : '';
    }

    final srcInput  = source.toLowerCase().replaceAll(RegExp(r'\(.*?\)'), '').trim();
    final destInput = destination.toLowerCase().replaceAll(RegExp(r'\(.*?\)'), '').trim();
    final srcCode   = extractCode(source);
    final destCode  = extractCode(destination);

    bool matchStation(String trainStation, String inputName, String inputCode) {
      final tsLower = trainStation.toLowerCase();
      final tsCode  = extractCode(trainStation);
      // Exact code match
      if (inputCode.isNotEmpty && tsCode == inputCode) return true;
      // Name contains input
      if (inputName.length >= 2 && tsLower.contains(inputName)) return true;
      // Input contains station name (partial)
      if (inputName.length >= 2 && tsLower.split(' (').first.toLowerCase().contains(inputName)) return true;
      // Code contains input (2+ chars)
      if (inputName.length >= 2 && tsCode.contains(inputName)) return true;
      return false;
    }

    final routeMatches = _allTrains.where((t) {
      final route = getRouteStations(t);
      
      int srcIdx = -1;
      for (int i = 0; i < route.length; i++) {
        if (matchStation(route[i], srcInput, srcCode)) {
          srcIdx = i;
          break;
        }
      }

      int destIdx = -1;
      for (int i = 0; i < route.length; i++) {
        if (matchStation(route[i], destInput, destCode)) {
          destIdx = i;
          break;
        }
      }

      return srcIdx != -1 && destIdx != -1 && srcIdx < destIdx;
    }).toList();

    // If no trains match this route, generate mock trains for the route dynamically
    if (routeMatches.isEmpty && source != destination) {
      final srcClean = source.split(' (').first;
      final destClean = destination.split(' (').first;
      final int numHash = (source.hashCode + destination.hashCode).abs() % 80000 + 10000;
      
      final train1 = Train(
        number: numHash.toString(),
        name: "${srcClean.toUpperCase()} - ${destClean.toUpperCase()} EXPRESS",
        source: source,
        destination: destination,
        departureTime: "08:15",
        arrivalTime: "21:30",
        duration: "13h 15m",
        classes: ["SL", "3A", "2A", "1A", "GN"],
        prices: {"SL": 540.0, "3A": 1450.0, "2A": 2100.0, "1A": 3500.0, "GN": 240.0},
        availability: {"SL": 142, "3A": 48, "2A": 16, "1A": 4, "GN": 300},
        type: "Express",
      );

      final train2 = Train(
        number: (numHash + 1).toString(),
        name: "${srcClean.toUpperCase()} - ${destClean.toUpperCase()} SF SPL",
        source: source,
        destination: destination,
        departureTime: "16:40",
        arrivalTime: "07:20",
        duration: "14h 40m",
        classes: ["3A", "2A", "SL"],
        prices: {"3A": 1620.0, "2A": 2350.0, "SL": 610.0},
        availability: {"3A": 88, "2A": 12, "SL": 190},
        type: "Express",
      );

      if (!_allTrains.any((t) => t.number == train1.number)) {
        _allTrains.add(train1);
        _allTrains.add(train2);
      }
      routeMatches.add(train1);
      routeMatches.add(train2);
    }

    // Filter by running days for the requested date
    return routeMatches.where((t) => runsOnDate(t, date)).toList();
  }

  List<Train> getAllTrains() => _allTrains;

  // ── Live route lookup ────────────────────────────────────────────────────────
  LiveTrainRoute getLiveRoute(String trainNumber) {
    if (trainNumber == "22436") {
      return LiveTrainRoute(
        trainNumber: "22436",
        trainName: "NDLS - BSB VANDE BHARAT EXP",
        currentStationIndex: 2,
        progressPercent: 0.65,
        stations: [
          LiveStationStatus("New Delhi (NDLS)", "06:00", "06:00", "06:00", "06:00", 0, 1, 0, 28.6430, 77.2223),
          LiveStationStatus("Kanpur Central (CNB)", "10:08", "10:10", "10:12", "10:15", 5, 5, 440, 26.4542, 80.3497),
          LiveStationStatus("Prayagraj Jn (PRYJ)", "12:08", "12:10", "12:20", "12:22", 12, 6, 634, 25.4497, 81.8268),
          LiveStationStatus("Varanasi Jn (BSB)", "14:00", "14:00", "14:15", "14:15", 15, 1, 755, 25.3263, 82.9876),
        ],
      );
    } else if (trainNumber == "12302") {
      return LiveTrainRoute(
        trainNumber: "12302",
        trainName: "HWH RAJDHANI EXPRESS",
        currentStationIndex: 1,
        progressPercent: 0.35,
        stations: [
          LiveStationStatus("New Delhi (NDLS)", "16:50", "16:50", "16:50", "16:50", 0, 9, 0, 28.6430, 77.2223),
          LiveStationStatus("Kanpur Central (CNB)", "21:30", "21:35", "21:32", "21:37", 2, 4, 440, 26.4542, 80.3497),
          LiveStationStatus("Prayagraj Jn (PRYJ)", "23:43", "23:45", "23:55", "23:57", 12, 5, 634, 25.4497, 81.8268),
          LiveStationStatus("Pt DD Upadhyaya (DDU)", "01:25", "01:35", "01:40", "01:50", 15, 2, 786, 25.2798, 83.1250),
          LiveStationStatus("Gaya Jn (GAYA)", "03:45", "03:48", "03:45", "03:48", 0, 3, 991, 24.7954, 84.9994),
          LiveStationStatus("Dhanbad Jn (DHN)", "06:33", "06:38", "06:35", "06:40", 2, 2, 1193, 23.7915, 86.4300),
          LiveStationStatus("Asansol Jn (ASN)", "07:28", "07:30", "07:30", "07:32", 2, 5, 1251, 23.6845, 86.9734),
          LiveStationStatus("Howrah Jn (HWH)", "09:55", "09:55", "09:55", "09:55", 0, 8, 1451, 22.5855, 88.3414),
        ],
      );
    } else {
      // Dynamic route generation for any number
      final int numVal = int.tryParse(trainNumber) ?? 12345;
      final int corridorIdx = numVal % 5;
      final List<Map<String, dynamic>> stationsData = _corridors[corridorIdx];

      String type = "Express";
      double speed = 70.0;
      String prefix = "EXP";
      if (trainNumber.startsWith("22") || trainNumber.startsWith("20")) {
        type = "Vande Bharat"; speed = 100.0; prefix = "VANDE BHARAT EXP";
      } else if (trainNumber.startsWith("12")) {
        if (numVal % 2 == 0) { type = "Rajdhani"; speed = 95.0; prefix = "RAJDHANI EXPRESS"; }
        else { type = "Shatabdi"; speed = 85.0; prefix = "SHATABDI EXP"; }
      }

      final String srcName  = stationsData.first["name"].toString().split(" (").first;
      final String destName = stationsData.last["name"].toString().split(" (").first;
      String trainName;
      if (type == "Rajdhani") {
        trainName = "${destName.toUpperCase()} RAJDHANI";
      } else {
        trainName = "${srcName.substring(0, math.min(4, srcName.length)).toUpperCase()} - ${destName.substring(0, math.min(4, destName.length)).toUpperCase()} $prefix";
      }

      final matchedTrain = _allTrains.firstWhere(
        (t) => t.number == trainNumber,
        orElse: () => Train(number: trainNumber, name: trainName, source: stationsData.first["name"], destination: stationsData.last["name"], departureTime: "06:00", arrivalTime: "22:00", duration: "16h", classes: ["CC"], prices: {}, availability: {}, type: type),
      );

      final List<String> routeStations = getRouteStations(matchedTrain);
      final int baseHour    = (numVal % 15) + 5;
      final int baseMinutes = baseHour * 60;
      final List<LiveStationStatus> stations = [];

      for (int i = 0; i < routeStations.length; i++) {
        final stationName = routeStations[i];
        final int travelMins = i * 60; // 1 hour per station
        final int arrMins    = baseMinutes + travelMins;
        final int depMins    = arrMins + (i == 0 || i == routeStations.length - 1 ? 0 : 5);
        final int delay      = i > 0 ? (numVal * i) % 45 : 0;
        
        // Find coordinates or default
        double lat = 25.0 + (i * 0.5);
        double lng = 80.0 + (i * 0.5);
        for (var corridor in _corridors) {
          for (var s in corridor) {
            if (s["name"] == stationName) {
              lat = s["lat"];
              lng = s["lng"];
              break;
            }
          }
        }

        stations.add(LiveStationStatus(
          stationName, _formatTime(i == 0 ? baseMinutes : arrMins), _formatTime(i == routeStations.length - 1 ? arrMins : depMins),
          _formatTime(i == 0 ? baseMinutes : arrMins + delay), _formatTime(i == routeStations.length - 1 ? arrMins + delay : depMins + delay),
          delay, ((numVal + i) % 8) + 1, i * 80, lat, lng,
        ));
      }

      return LiveTrainRoute(
        trainNumber: trainNumber,
        trainName: matchedTrain.name,
        currentStationIndex: math.min(1, stations.length - 2),
        progressPercent: 0.55,
        stations: stations,
      );
    }
  }

  static String _formatTime(int minutesFromMidnight) {
    int hours = (minutesFromMidnight ~/ 60) % 24;
    int mins  = minutesFromMidnight % 60;
    return "${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}";
  }

  static final List<List<Map<String, dynamic>>> _corridors = [
    // Corridor 0: Delhi – Kolkata
    [
      {"name": "New Delhi (NDLS)", "dist": 0,    "lat": 28.6430, "lng": 77.2223},
      {"name": "Kanpur Central (CNB)", "dist": 440,  "lat": 26.4542, "lng": 80.3497},
      {"name": "Prayagraj Jn (PRYJ)", "dist": 634,  "lat": 25.4497, "lng": 81.8268},
      {"name": "Patna Jn (PNBE)", "dist": 998,  "lat": 25.6022, "lng": 85.1376},
      {"name": "Asansol Jn (ASN)", "dist": 1251, "lat": 23.6845, "lng": 86.9734},
      {"name": "Howrah Jn (HWH)", "dist": 1451, "lat": 22.5855, "lng": 88.3414},
    ],
    // Corridor 1: Delhi – Mumbai
    [
      {"name": "New Delhi (NDLS)", "dist": 0,    "lat": 28.6430, "lng": 77.2223},
      {"name": "Agra Cantt (AGC)", "dist": 195,  "lat": 27.1587, "lng": 77.9904},
      {"name": "Kota Jn (KOTA)", "dist": 465,  "lat": 25.2138, "lng": 75.8648},
      {"name": "Vadodara Jn (BRC)", "dist": 990,  "lat": 22.3106, "lng": 73.1812},
      {"name": "Surat (ST)", "dist": 1120, "lat": 21.2049, "lng": 72.8406},
      {"name": "Mumbai Central (MMCT)", "dist": 1384, "lat": 18.9696, "lng": 72.8193},
    ],
    // Corridor 2: Delhi – Chennai
    [
      {"name": "New Delhi (NDLS)", "dist": 0,    "lat": 28.6430, "lng": 77.2223},
      {"name": "Agra Cantt (AGC)", "dist": 195,  "lat": 27.1587, "lng": 77.9904},
      {"name": "Bhopal Jn (BPL)", "dist": 700,  "lat": 23.2599, "lng": 77.4126},
      {"name": "Nagpur Jn (NGP)", "dist": 1090, "lat": 21.1458, "lng": 79.0882},
      {"name": "Vijayawada Jn (BZA)", "dist": 1750, "lat": 16.5062, "lng": 80.6480},
      {"name": "Chennai Central (MAS)", "dist": 2180, "lat": 13.0827, "lng": 80.2707},
    ],
    // Corridor 3: Mumbai – Bengaluru
    [
      {"name": "Mumbai Central (MMCT)", "dist": 0,    "lat": 18.9696, "lng": 72.8193},
      {"name": "Pune Jn (PUNE)", "dist": 190,  "lat": 18.5284, "lng": 73.8739},
      {"name": "Solapur Jn (SUR)", "dist": 450,  "lat": 17.6599, "lng": 75.9064},
      {"name": "Secunderabad Jn (SC)", "dist": 800,  "lat": 17.4334, "lng": 78.5015},
      {"name": "Guntakal Jn (GTL)", "dist": 1150, "lat": 15.1663, "lng": 77.3705},
      {"name": "KSR Bengaluru (SBC)", "dist": 1430, "lat": 12.9779, "lng": 77.5724},
    ],
    // Corridor 4: Kolkata – Chennai
    [
      {"name": "Howrah Jn (HWH)", "dist": 0,    "lat": 22.5855, "lng": 88.3414},
      {"name": "Bhubaneswar (BBS)", "dist": 437,  "lat": 20.2600, "lng": 85.8400},
      {"name": "Visakhapatnam (VSKP)", "dist": 879,  "lat": 17.7291, "lng": 83.3086},
      {"name": "Vijayawada Jn (BZA)", "dist": 1230, "lat": 16.5062, "lng": 80.6480},
      {"name": "Chennai Central (MAS)", "dist": 1660, "lat": 13.0827, "lng": 80.2707},
    ],
  ];
}

class LiveTrainRoute {
  final String trainNumber;
  final String trainName;
  final int currentStationIndex;
  final double progressPercent;
  final List<LiveStationStatus> stations;

  LiveTrainRoute({
    required this.trainNumber,
    required this.trainName,
    required this.currentStationIndex,
    required this.progressPercent,
    required this.stations,
  });

  String get currentStatusDescription {
    if (currentStationIndex >= stations.length - 1) {
      return "Reached destination ${stations.last.name}";
    }
    final current = stations[currentStationIndex];
    final next    = stations[currentStationIndex + 1];
    if (current.delayMinutes > 0) {
      return "Departed ${current.name} delayed by ${current.delayMinutes} mins. Next: ${next.name} (${next.scheduledArrival})";
    } else {
      return "Departed ${current.name} on time. Next: ${next.name} (${next.scheduledArrival})";
    }
  }
}

class LiveStationStatus {
  final String name;
  final String scheduledArrival;
  final String scheduledDeparture;
  final String actualArrival;
  final String actualDeparture;
  final int delayMinutes;
  final int platform;
  final int distanceKm;
  final double latitude;
  final double longitude;

  LiveStationStatus(
    this.name,
    this.scheduledArrival,
    this.scheduledDeparture,
    this.actualArrival,
    this.actualDeparture,
    this.delayMinutes,
    this.platform,
    this.distanceKm,
    this.latitude,
    this.longitude,
  );
}
