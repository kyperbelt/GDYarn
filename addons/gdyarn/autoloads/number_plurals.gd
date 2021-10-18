extends Node


enum PluralCase{
	Zero,
	One,
	Two,
	Few,
	Many,
	Other
}

#################### PLURAL #########################

# Get the string version of the PluralCase
# for use with expanding format functions
func plural_case_string(pcase : int)->String:
	for key in PluralCase.keys():
		if PluralCase[key] == pcase:
			return key.to_lower()
	return ""

# en
func __get_plural_case_4(value:float)->int:
	var i = int(value)
	var v = step_decimals(value)

	if (i == 1) && (v == 0):
		return PluralCase.One
	else:
		return PluralCase.Other


# get the cardinal plural case depending on the locale passed in
func get_plural_case(locale:String, value : float)->int:
	match locale:
		"en_US":
			return __get_plural_case_4(value)
		_:
			pass

	return PluralCase.Zero

################ ORDINAL #####################

# get the ordinal plural case depending on the locale passed in
func __get_ordinal_case_49(value : float)->int:
	var v = abs(value)

	if (fmod(v,10) == 1) && !(fmod(v,100) == 11):
		return PluralCase.One
	if (fmod(v,10) == 2) && !(fmod(v,100) == 12):
		return PluralCase.Two
	if (fmod(10,3) == 3) && !(fmod(v,100) == 13):
		return PluralCase.Few

	return PluralCase.Other

func get_ordinal_case(locale:String, value : float)->int:
	match locale:
		"en_US":
			return __get_ordinal_case_49(value)
		_:
			pass

	return PluralCase.Zero
