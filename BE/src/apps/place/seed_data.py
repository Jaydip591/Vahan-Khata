"""
Shared place list (English, Gujarati), roughly in order of how often a Gujarat
transport business goes there. Edit freely: ensure_seed_places() adds new rows
and fixes spellings of existing ones on the next start.
"""

SEED_PLACES: list[tuple[str, str]] = [
    # Most used
    ("Surat", "સુરત"), ("Ahmedabad", "અમદાવાદ"), ("Vadodara", "વડોદરા"), ("Rajkot", "રાજકોટ"),
    ("Mumbai", "મુંબઈ"), ("Vapi", "વાપી"), ("Valsad", "વલસાડ"), ("Navsari", "નવસારી"),
    ("Bharuch", "ભરૂચ"), ("Ankleshwar", "અંકલેશ્વર"), ("Anand", "આણંદ"), ("Morbi", "મોરબી"),
    ("Gandhinagar", "ગાંધીનગર"), ("Bhavnagar", "ભાવનગર"), ("Jamnagar", "જામનગર"),
    ("Junagadh", "જૂનાગઢ"), ("Mehsana", "મહેસાણા"), ("Surendranagar", "સુરેન્દ્રનગર"),
    ("Gandhidham", "ગાંધીધામ"), ("Bhuj", "ભુજ"), ("Nadiad", "નડિયાદ"), ("Palanpur", "પાલનપુર"),
    ("Porbandar", "પોરબંદર"), ("Amreli", "અમરેલી"), ("Godhra", "ગોધરા"), ("Dahod", "દાહોદ"),
    ("Himmatnagar", "હિંમતનગર"), ("Patan", "પાટણ"), ("Kalol", "કલોલ"), ("Botad", "બોટાદ"),
    # Surat belt
    ("Sachin", "સચિન"), ("Pandesara", "પાંડેસરા"), ("Udhna", "ઉધના"), ("Hazira", "હજીરા"),
    ("Kamrej", "કામરેજ"), ("Kim", "કીમ"), ("Kosamba", "કોસંબા"), ("Olpad", "ઓલપાડ"),
    ("Palsana", "પલસાણા"), ("Bardoli", "બારડોલી"), ("Mandvi", "માંડવી"), ("Mangrol", "માંગરોળ"),
    ("Vyara", "વ્યારા"), ("Songadh", "સોનગઢ"),
    # South Gujarat
    ("Bilimora", "બીલીમોરા"), ("Gandevi", "ગણદેવી"), ("Chikhli", "ચીખલી"), ("Vansda", "વાંસદા"),
    ("Dharampur", "ધરમપુર"), ("Pardi", "પારડી"), ("Umbergaon", "ઉમરગામ"), ("Sarigam", "સરીગામ"),
    ("Silvassa", "સિલવાસા"), ("Daman", "દમણ"), ("Diu", "દીવ"),
    # Bharuch / Narmada
    ("Dahej", "દહેજ"), ("Jhagadia", "ઝઘડિયા"), ("Netrang", "નેત્રંગ"), ("Rajpipla", "રાજપીપળા"),
    ("Jambusar", "જંબુસર"), ("Vagra", "વાગરા"), ("Sayan", "સાયણ"),
    # Central Gujarat
    ("Karjan", "કરજણ"), ("Padra", "પાદરા"), ("Dabhoi", "ડભોઈ"), ("Halol", "હાલોલ"),
    ("Lunawada", "લુણાવાડા"), ("Chhota Udaipur", "છોટા ઉદેપુર"), ("Borsad", "બોરસદ"),
    ("Khambhat", "ખંભાત"), ("Petlad", "પેટલાદ"), ("Umreth", "ઉમરેઠ"),
    ("Vallabh Vidyanagar", "વલ્લભ વિદ્યાનગર"), ("Kheda", "ખેડા"), ("Kapadvanj", "કપડવંજ"),
    ("Mahemdavad", "મહેમદાવાદ"), ("Balasinor", "બાલાસિનોર"), ("Santrampur", "સંતરામપુર"),
    ("Jhalod", "ઝાલોદ"), ("Devgadh Baria", "દેવગઢ બારિયા"), ("Shehra", "શહેરા"),
    # Ahmedabad belt
    ("Sanand", "સાણંદ"), ("Viramgam", "વિરમગામ"), ("Dholka", "ધોળકા"), ("Bavla", "બાવળા"),
    ("Changodar", "ચાંગોદર"), ("Naroda", "નરોડા"), ("Vatva", "વટવા"), ("Odhav", "ઓઢવ"),
    ("Narol", "નારોલ"), ("Aslali", "અસલાલી"), ("Kathwada", "કઠવાડા"), ("Sarkhej", "સરખેજ"),
    ("Bopal", "બોપલ"), ("Chhatral", "છત્રાલ"), ("Dehgam", "દહેગામ"), ("Mansa", "માણસા"),
    # North Gujarat
    ("Kadi", "કડી"), ("Unjha", "ઊંઝા"), ("Visnagar", "વિસનગર"), ("Sidhpur", "સિદ્ધપુર"),
    ("Harij", "હારીજ"), ("Radhanpur", "રાધનપુર"), ("Deesa", "ડીસા"), ("Dhanera", "ધાનેરા"),
    ("Tharad", "થરાદ"), ("Ambaji", "અંબાજી"), ("Idar", "ઈડર"), ("Modasa", "મોડાસા"),
    ("Bayad", "બાયડ"), ("Prantij", "પ્રાંતિજ"), ("Talod", "તલોદ"), ("Khedbrahma", "ખેડબ્રહ્મા"),
    # Saurashtra
    ("Gondal", "ગોંડલ"), ("Jetpur", "જેતપુર"), ("Dhoraji", "ધોરાજી"), ("Upleta", "ઉપલેટા"),
    ("Jasdan", "જસદણ"), ("Wankaner", "વાંકાનેર"), ("Halvad", "હળવદ"), ("Dhrangadhra", "ધ્રાંગધ્રા"),
    ("Chotila", "ચોટીલા"), ("Limbdi", "લીંબડી"), ("Sayla", "સાયલા"), ("Thangadh", "થાનગઢ"),
    ("Dhrol", "ધ્રોલ"), ("Kalavad", "કાલાવડ"), ("Khambhalia", "ખંભાળિયા"), ("Dwarka", "દ્વારકા"),
    ("Keshod", "કેશોદ"), ("Veraval", "વેરાવળ"), ("Somnath", "સોમનાથ"), ("Una", "ઊના"),
    ("Kodinar", "કોડીનાર"), ("Talala", "તાલાલા"), ("Visavadar", "વિસાવદર"), ("Rajula", "રાજુલા"),
    ("Savarkundla", "સાવરકુંડલા"), ("Dhari", "ધારી"), ("Mahuva", "મહુવા"), ("Palitana", "પાલીતાણા"),
    ("Sihor", "સિહોર"), ("Talaja", "તળાજા"), ("Pipavav", "પીપાવાવ"),
    # Kutch
    ("Mundra", "મુન્દ્રા"), ("Kandla", "કંડલા"), ("Anjar", "અંજાર"), ("Bhachau", "ભચાઉ"),
    ("Rapar", "રાપર"), ("Nakhatrana", "નખત્રાણા"),
    # Maharashtra
    ("Pune", "પુણે"), ("Nashik", "નાસિક"), ("Thane", "થાણે"), ("Navi Mumbai", "નવી મુંબઈ"),
    ("Bhiwandi", "ભિવંડી"), ("Nhava Sheva", "ન્હાવા શેવા"), ("Nagpur", "નાગપુર"),
    ("Aurangabad", "ઔરંગાબાદ"), ("Kolhapur", "કોલ્હાપુર"), ("Sangli", "સાંગલી"),
    ("Solapur", "સોલાપુર"), ("Dhule", "ધુળે"), ("Jalgaon", "જળગાંવ"),
    # Rajasthan
    ("Udaipur", "ઉદયપુર"), ("Jaipur", "જયપુર"), ("Jodhpur", "જોધપુર"), ("Ajmer", "અજમેર"),
    ("Kota", "કોટા"), ("Bhilwara", "ભીલવાડા"), ("Abu Road", "આબુ રોડ"), ("Sirohi", "સિરોહી"),
    ("Pali", "પાલી"), ("Barmer", "બાડમેર"), ("Jalore", "જાલોર"), ("Banswara", "બાંસવાડા"),
    # Madhya Pradesh
    ("Indore", "ઇન્દોર"), ("Bhopal", "ભોપાલ"), ("Ujjain", "ઉજ્જૈન"), ("Ratlam", "રતલામ"),
    ("Neemuch", "નીમચ"), ("Mandsaur", "મંદસૌર"),
    # Rest of India
    ("Delhi", "દિલ્હી"), ("Gurugram", "ગુરુગ્રામ"), ("Faridabad", "ફરીદાબાદ"), ("Agra", "આગ્રા"),
    ("Lucknow", "લખનૌ"), ("Kanpur", "કાનપુર"), ("Ludhiana", "લુધિયાણા"), ("Chandigarh", "ચંડીગઢ"),
    ("Hyderabad", "હૈદરાબાદ"), ("Bengaluru", "બેંગલુરુ"), ("Chennai", "ચેન્નઈ"), ("Kolkata", "કોલકાતા"),
]
