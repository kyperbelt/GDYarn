extends Node

enum PluralCase { Zero, One, Two, Few, Many, Other, NoPluralisation }

#################### PLURAL #########################
#################### Current Cardinal Plural Support:
#################### - "en", "ast", "ca", "de", "et", "fi", "fy", "gl", "ia", "io", "it", "ji", "nl", "sc", "scn", "sv", "sw", "ur", "yi":
#################### - 	"bm","bo", "dz", "id", "ig", "ii", "in", "ja", "jbo",  "jv", "jw", "kde", "kea",
####################    "km", "ko", "lkt", "lo", "ms","my","nqo", "osa", "root", "sah", "ses", "sg", "su",
####################    "th","to", "vi", "wo", "yo", "yue", "zh


# Get the string version of the PluralCase
# for use with expanding format functions
func plural_case_string(pcase: int) -> String:
	for key in PluralCase.keys():
		if PluralCase[key] == pcase:
			return key.to_lower()
	return ""


# bm, bo, dz, id, ig, ii, in , ja, jbo, jv,
# jw, kde, kea, km, kok, lkt, lo, ms, my, nqo,
# osa, root, sah, ses, sg, su, th, to, vi, wo,
# yo, yue, zh
func __get_plural_case_0(value: float) -> int:
	return PluralCase.Other


# am, as, bn, fa, gu, hi, kn, zu
func __get_plural_case_1(value: float) -> int:
	var v = int(abs(value))
	if v == 0 || v == 1:
		return PluralCase.One

	return PluralCase.Other


# ff, fr, hy, kab
func __get_plural_case_2(value: float) -> int:
	var v := int(value)

	if v == 0 || v == 1:
		return PluralCase.One

	return PluralCase.Other


# pt
func __get_plural_case_3(value: float) -> int:
	var v := int(value)

	if v >= 0 && v <= 1:
		return PluralCase.One

	return PluralCase.Other


# en
func __get_plural_case_4(value: float) -> int:
	var i = int(value)
	var v = step_decimals(value)

	if (i == 1) && (v == 0):
		return PluralCase.One
	else:
		return PluralCase.Other


func __get_plural_case_5(value: float) -> int:
	var n = abs(value)
	var i = int(value)
	var f = get_fraction(value)

	if (n == 0 || n == 1) || (i == 0 && f == 1):
		return PluralCase.One

	return PluralCase.Other


func __get_plural_case_6(value: float) -> int:
	var n := int(abs(value))
	if n >= 0 && n <= 1:
		return PluralCase.One

	return PluralCase.Other


func __get_plural_case_7(value: float) -> int:
	var n := int(abs(value))
	if (n >= 0 && n <= 1) || (n >= 11 && n <= 99):
		return PluralCase.One
	return PluralCase.Other


func __get_plural_case_8(value: float) -> int:
	var n := int(abs(value))
	if n == 1:
		return PluralCase.One
	return PluralCase.Other


func __get_plural_case_9(value: float) -> int:
	var n := abs(value)
	var i := int(value)
	var f := get_fraction(value)

	if n == 1 || (!((f == 0) && i == 0) || i == 1):
		return PluralCase.One
	return PluralCase.Other


func __get_plural_case_10(value: float) -> int:
	var i := int(value)
	var f := get_fraction(value)

	if !(f == 0) || (i % 10 == 1 && !(i % 100 == 11)):
		return PluralCase.One

	return PluralCase.Other


func __get_plural_case_11(value: float) -> int:
	var i = int(value)
	var v = step_decimals(value)
	var f = get_fraction(value)

	if (v == 0 && i % 10 == 1 && !(i % 100 == 11)) || (f % 10 == 1 && !(f % 100 == 11)):
		return PluralCase.One

	return PluralCase.Other


func __get_plural_case_12(value: float) -> int:
	var i := int(value)
	var v := step_decimals(value)
	var f := get_fraction(value)
	if (
		((v == 0) && (i == 1) || (i == 2) || (i == 3))
		|| ((v == 0) && !(((i % 10) == 4) || ((i % 10) == 6) || ((i % 10) == 9)))
		|| (!(v == 0) && !(((f % 10) == 4) || ((f % 10) == 6) || ((f % 10) == 9)))
	):
		return PluralCase.One

	return PluralCase.Other


func __get_plural_case_13(value: float) -> int:
	var n := int(abs(value))
	var v := step_decimals(value)
	var f := get_fraction(value)

	if (
		((n % 10) == 0)
		|| ((n % 100) >= 11 && (n % 100) <= 19)
		|| ((v == 2) && ((f % 100) >= 11 && (f % 100) <= 19))
	):
		return PluralCase.Zero

	if (
		(((n % 10) == 1) && !((n % 100) == 11))
		|| ((v == 2) && ((f % 10) == 1) && !((f % 100) == 11))
		|| (!(v == 2) && ((f % 10) == 1))
	):
		return PluralCase.One

	return PluralCase.Other


func __get_plural_case_14(value: float) -> int:
	var n := abs(value)
	var i := int(value)

	if n == 0:
		return PluralCase.Zero
	elif i == 0 || i == 1 && !(n == 0):
		return PluralCase.One

	return PluralCase.Other


func __get_plural_case_15(value: float) -> int:
	var n := abs(value)
	return PluralCase.Zero if n == 0 else PluralCase.One if n == 1 else PluralCase.Other


func __get_plural_case_16(value: float) -> int:
	var n := abs(value)
	return PluralCase.One if n == 1 else PluralCase.Two if n == 2 else PluralCase.Other


func __get_plural_case_17(value: float) -> int:
	var n := abs(value)
	var i := int(value)

	if i == 0 || n == 1:
		return PluralCase.One
	elif n >= 2 && n <= 10:
		return PluralCase.Few

	return PluralCase.Other


func __get_plural_case_18(value: float) -> int:
	var n := int(abs(value))
	var i := int(value)
	var v := step_decimals(value)

	if i == 1 && v == 0:
		return PluralCase.One
	if !(v == 0) || n == 0 || (n % 100 >= 2 && n % 100 <= 19):
		return PluralCase.Few
	return PluralCase.Other


func __get_plural_case_19(value: float) -> int:
	var i := int(value)
	var v := step_decimals(value)
	var f := get_fraction(value)

	if (v == 0 && (i % 10 == 1) && !(i % 100 == 11)) || (f % 10 == 1 && !(f % 100 == 11)):
		return PluralCase.One

	if (
		((v == 0) && ((i % 10) >= 2 && (i % 10) <= 4) && !((i % 100) >= 12 && (i % 100) <= 14))
		|| (((f % 10) >= 2 && (f % 10) <= 4) && !((f % 100) >= 12 && (f % 100) <= 14))
	):
		return PluralCase.Few

	return PluralCase.Other


func __get_plural_case_20(value: float) -> int:
	var n := abs(value)

	if n == 1 || n == 11:
		return PluralCase.One

	if n == 2 || n == 12:
		return PluralCase.Two

	if n >= 3 && n <= 10 || n >= 13 && n <= 19:
		return PluralCase.Few

	return PluralCase.Other


func __get_plural_case_21(value: float) -> int:
	var i := int(value)
	var v := step_decimals(value)

	if v == 0 && i % 100 == 1:
		return PluralCase.One
	if v == 0 && i % 100 == 2:
		return PluralCase.Two
	if (v == 0 && i % 100 >= 3 && i % 100 <= 4) || !(v == 0):
		return PluralCase.Few

	return PluralCase.Other


func __get_plural_case_22(value: float) -> int:
	var i := int(value)
	var v := step_decimals(value)
	var f := get_fraction(value)
	if ((v == 0) && ((i % 100) == 1)) || ((f % 100) == 1):
		return PluralCase.One

	if ((v == 0) && ((i % 100) == 2)) || ((f % 100) == 2):
		return PluralCase.Two

	if ((v == 0) && ((i % 100) >= 3 && (i % 100) <= 4)) || ((f % 100) >= 3 && (f % 100) <= 4):
		return PluralCase.Few

	return PluralCase.Other


func __get_plural_case_23(value: float) -> int:
	var n := int(abs(value))
	var i := int(value)
	var v := step_decimals(value)

	if i == 1 && v == 0:
		return PluralCase.One
	if i == 2 && v == 0:
		return PluralCase.Two
	if v == 0 && !(n >= 0 && n <= 10) && n % 10 == 0:
		return PluralCase.Many

	return PluralCase.Other


func __get_plural_case_24(value: float) -> int:
	var i := int(value)
	var v := step_decimals(value)

	if i == 1 && v == 0:
		return PluralCase.One
	if i >= 2 && i <= 4 && v == 0:
		return PluralCase.Few
	if !(v == 0):
		return PluralCase.Many

	return PluralCase.Other


func __get_plural_case_25(value: float) -> int:
	var i := int(value)
	var v := step_decimals(value)

	if i == 1 && v == 0:
		return PluralCase.One
	if (v == 0) && ((i % 10) >= 2 && (i % 10) <= 4) && !((i % 100) >= 12 && (i % 100) <= 14):
		return PluralCase.Few
	if (
		((v == 0) && !(i == 1) && ((i % 10) >= 0 && (i % 10) <= 1))
		|| ((v == 0) && ((i % 10) >= 5 && (i % 10) <= 9))
		|| ((v == 0) && ((i % 100) >= 12 && (i % 100) <= 14))
	):
		return PluralCase.Many

	return PluralCase.Other


func __get_plural_case_26(value: float) -> int:
	var n := int(abs(value))

	if n % 10 == 1 && !(n % 100 == 11):
		return PluralCase.One
	if ((n % 10) >= 2 && (n % 10) <= 4) && !((n % 100) >= 12 && (n % 100) <= 14):
		return PluralCase.Few
	if ((n % 10) == 0) || ((n % 10) >= 5 && (n % 10) <= 9) || ((n % 100) >= 11 && (n % 100) <= 14):
		return PluralCase.Many
	return PluralCase.Other


func __get_plural_case_27(value: float) -> int:
	var n := int(abs(value))
	var f := get_fraction(value)

	if ((n % 10) == 1) && !((n % 100) >= 11 && (n % 100) <= 19):
		return PluralCase.One
	if ((n % 10) >= 2 && (n % 10) <= 9) && !((n % 100) >= 11 && (n % 100) <= 19):
		return PluralCase.Few
	if !(f == 0):
		return PluralCase.Many
	return PluralCase.Other


func __get_plural_case_28(value: float) -> int:
	var n := int(abs(value))
	if n == 1:
		return PluralCase.One
	if n == 0 || (n % 100 >= 2 && n % 100 <= 10):
		return PluralCase.Few
	if n % 100 >= 11 && n % 100 <= 19:
		return PluralCase.Many
	return PluralCase.Other


func __get_plural_case_29(value: float) -> int:
	var i := int(value)
	var v := step_decimals(value)

	if (v == 0) && ((i % 10) == 1) && !((i % 100) == 11):
		return PluralCase.One
	if (v == 0) && ((i % 10) >= 2 && (i % 10) <= 4) && !((i % 100) >= 12 && (i % 100) <= 14):
		return PluralCase.Few
	if (
		((v == 0) && ((i % 10) == 0))
		|| ((v == 0) && ((i % 10) >= 5 && (i % 10) <= 9))
		|| ((v == 0) && ((i % 100) >= 11 && (i % 100) <= 14))
	):
		return PluralCase.Many
	return PluralCase.Other


func __get_plural_case_30(value: float) -> int:
	var n := int(abs(value))

	if ((n % 10) == 1) && !(((n % 100) == 11) || ((n % 100) == 71) || ((n % 100) == 91)):
		return PluralCase.One
	if ((n % 10) == 2) && !(((n % 100) == 12) || ((n % 100) == 72) || ((n % 100) == 92)):
		return PluralCase.Two
	if (
		((n % 10) >= 3 && (n % 10) <= 4)
		|| (
			((n % 10) == 9)
			&& !(
				((n % 100) >= 10 && (n % 100) <= 19)
				|| ((n % 100) >= 70 && (n % 100) <= 79)
				|| ((n % 100) >= 90 && (n % 100) <= 99)
			)
		)
	):
		return PluralCase.Few
	if !(n == 0) && n % 1000000 == 0:
		return PluralCase.Many
	return PluralCase.Other


func __get_plural_case_31(value: float) -> int:
	var n := abs(value)
	if n == 1:
		return PluralCase.One
	if n == 2:
		return PluralCase.Two
	if n >= 3 && n <= 6:
		return PluralCase.Few
	if n >= 7 && n <= 10:
		return PluralCase.Many
	return PluralCase.Other


func __get_plural_case_32(value: float) -> int:
	var i := int(value)
	var v := step_decimals(value)

	if v == 0 && i % 10 == 1:
		return PluralCase.One
	if v == 0 && i % 10 == 2:
		return PluralCase.Two
	if (
		(v == 0) && ((i % 100) == 0)
		|| ((i % 100) == 20)
		|| ((i % 100) == 40)
		|| ((i % 100) == 60)
		|| ((i % 100) == 80)
	):
		return PluralCase.Few
	if v != 0:
		return PluralCase.Many

	return PluralCase.Other


func __get_plural_case_33(value: float) -> int:
	var n := int(abs(value))

	if n == 0:
		return PluralCase.Zero
	if n == 1:
		return PluralCase.One
	if (
		(
			((n % 100) == 2)
			|| ((n % 100) == 22)
			|| ((n % 100) == 42)
			|| ((n % 100) == 62)
			|| ((n % 100) == 82)
		)
		|| (
			((n % 1000) == 0) && ((n % 100000) >= 1000 && (n % 100000) <= 20000)
			|| ((n % 100000) == 40000)
			|| ((n % 100000) == 60000)
			|| ((n % 100000) == 80000)
		)
		|| (!(n == 0) && ((n % 1000000) == 100000))
	):
		return PluralCase.Two
	if (
		((n % 100) == 3)
		|| ((n % 100) == 23)
		|| ((n % 100) == 43)
		|| ((n % 100) == 63)
		|| ((n % 100) == 83)
	):
		return PluralCase.Few
	if (
		!(n == 1) && ((n % 100) == 1)
		|| ((n % 100) == 21)
		|| ((n % 100) == 41)
		|| ((n % 100) == 61)
		|| ((n % 100) == 81)
	):
		return PluralCase.Many
	return PluralCase.Other


func __get_plural_case_34(value: float) -> int:
	var n := int(abs(value))

	if n == 0:
		return PluralCase.Zero
	if n == 1:
		return PluralCase.One
	if n == 2:
		return PluralCase.Two
	if n % 100 >= 3 && n % 100 <= 10:
		return PluralCase.Few
	if n % 100 >= 11 && n % 100 <= 99:
		return PluralCase.Many
	return PluralCase.Other


func __get_plural_case_35(value: float) -> int:
	var n := abs(value)
	if n == 0:
		return PluralCase.Zero
	if n == 1:
		return PluralCase.One
	if n == 2:
		return PluralCase.Two
	if n == 3:
		return PluralCase.Few
	if n == 6:
		return PluralCase.Many
	return PluralCase.Other


# get the cardinal plural case depending on the locale passed in
func get_plural_case(locale: String, value: float) -> int:
	match locale:
		"bm", "bo", "dz", "id", "ig", "ii", "in", "ja", "jbo", "jv", "jw", "kde", "kea", "km", "ko", "lkt", "lo", "ms", "my", "nqo", "osa", "root", "sah", "ses", "sg", "su", "th", "to", "vi", "wo", "yo", "yue", "zh":
			return __get_plural_case_0(value)
		"am", "as", "bn", "fa", "gu", "hi", "kn", "zu":
			return __get_plural_case_1(value)
		"ff", "fr", "hy", "kab":
			return __get_plural_case_2(value)
		"pt":
			return __get_plural_case_3(value)
		"en", "ast", "ca", "de", "et", "fi", "fy", "gl", "ia", "io", "it", "ji", "nl", "sc", "scn", "sv", "sw", "ur", "yi":
			return __get_plural_case_4(value)
		"si":
			return __get_plural_case_5(value)
		"ak", "bho", "guw", "ln", "mg", "nso", "pa", "ti", "wa":
			return __get_plural_case_6(value)
		"tzm":
			return __get_plural_case_7(value)
		"af", "an", "asa", "az", "bem", "bez", "bg", "brx", "ce", "cgg", "chr", "ckb", "dv", "ee", "el", "eo", "es", "eu", "fo", "fur", "gsw", "ha", "haw", "hu", "jgo", "jmc", "ka", "kaj", "kcg", "kk", "kkj", "kl", "ks", "ksb", "ku", "ky", "lb", "lg", "mas", "mgo", "ml", "mn", "mr", "nah", "nb", "nd", "ne", "nn", "nnh", "no", "nr", "ny", "nyn", "om", "or", "os", "pap", "ps", "rm", "rof", "rwk", "saq", "sd", "sdh", "seh", "sn", "so", "sq", "ss", "ssy", "st", "syr", "ta", "te", "teo", "tig", "tk", "tn", "tr", "ts", "ug", "uz", "ve", "vo", "vun", "wae", "xh", "xog":
			return __get_plural_case_8(value)
		"da":
			return __get_plural_case_9(value)
		"is":
			return __get_plural_case_10(value)
		"mk":
			return __get_plural_case_11(value)
		"ceb", "fil", "tl":
			return __get_plural_case_12(value)
		"lv", "prg":
			return __get_plural_case_13(value)
		"lag":
			return __get_plural_case_14(value)
		"ksh":
			return __get_plural_case_15(value)
		"ui", "naq", "se", "sma", "smi", "smj", "smn", "sms":
			return __get_plural_case_16(value)
		"shi":
			return __get_plural_case_17(value)
		"mo", "ro":
			return __get_plural_case_18(value)
		"bs", "hr", "sh", "sr":
			return __get_plural_case_19(value)
		"gd":
			return __get_plural_case_20(value)
		"sl":
			return __get_plural_case_21(value)
		"dsb", "hsb":
			return __get_plural_case_22(value)
		"he", "iw":
			return __get_plural_case_23(value)
		"cs", "sk":
			return __get_plural_case_24(value)
		"pl":
			return __get_plural_case_25(value)
		"be":
			return __get_plural_case_26(value)
		"lt":
			return __get_plural_case_27(value)
		"mt":
			return __get_plural_case_28(value)
		"ru", "uk":
			return __get_plural_case_29(value)
		"br":
			return __get_plural_case_30(value)
		"ga":
			return __get_plural_case_31(value)
		"gv":
			return __get_plural_case_32(value)
		"kw":
			return __get_plural_case_33(value)
		"ar", "ars":
			return __get_plural_case_34(value)
		"cy":
			return __get_plural_case_35(value)
		_:
			pass

	return PluralCase.NoPluralisation


################ ORDINAL #####################


func __get_ordinal_case_36(value: float) -> int:
	return PluralCase.Other


func __get_ordinal_case_37(value: float) -> int:
	var n := int(abs(value))
	if ((n % 10) == 1) || ((n % 10) == 2) && !(((n % 100) == 11) || ((n % 100) == 12)):
		return PluralCase.One

	return PluralCase.Other


func __get_ordinal_case_38(value: float) -> int:
	var n := int(abs(value))
	if n == 1:
		return PluralCase.One
	return PluralCase.Other


func __get_ordinal_case_39(value: float) -> int:
	var n := int(abs(value))
	if n == 1 || n == 5:
		return PluralCase.One
	return PluralCase.Other


func __get_ordinal_case_40(value: float) -> int:
	var n := int(abs(value))
	if n >= 1 && n <= 4:
		return PluralCase.One
	return PluralCase.Other


func __get_ordinal_case_41(value: float) -> int:
	var n := int(abs(value))
	if ((n % 10) == 2) || ((n % 10) == 3) && !(((n % 100) == 12) || ((n % 100) == 13)):
		return PluralCase.Few

	return PluralCase.Other


func __get_ordinal_case_42(value: float) -> int:
	var n := int(abs(value))
	if n % 10 == 3 && !(n % 100 == 13):
		return PluralCase.Few
	return PluralCase.Other


func __get_ordinal_case_43(value: float) -> int:
	var n := int(abs(value))
	if n % 10 == 6 || n % 10 == 9 || n == 10:
		return PluralCase.Few
	return PluralCase.Other


func __get_ordinal_case_44(value: float) -> int:
	var n := int(abs(value))
	if ((n % 10) == 6) || ((n % 10) == 9) || (((n % 10) == 0) && !(n == 0)):
		return PluralCase.Many

	return PluralCase.Other


func __get_ordinal_case_45(value: float) -> int:
	var n := int(abs(value))

	if (n == 11) || (n == 8) || (n == 80) || (n == 800):
		return PluralCase.Many

	return PluralCase.Other


func __get_ordinal_case_46(value: float) -> int:
	var i = int(value)
	if i == 1:
		return PluralCase.One
	if (
		(i == 0)
		|| (
			((i % 100) >= 2 && (i % 100) <= 20)
			|| ((i % 100) == 40)
			|| ((i % 100) == 60)
			|| ((i % 100) == 80)
		)
	):
		return PluralCase.Many
	return PluralCase.Other


func __get_ordinal_case_47(value: float) -> int:
	var n := int(abs(value))
	if n == 1:
		return PluralCase.One
	if n % 10 == 4 && !(n % 100 == 14):
		return PluralCase.Many
	return PluralCase.Other


func __get_ordinal_case_48(value: float) -> int:
	var n := int(abs(value))

	if (
		(n >= 1 && n <= 4)
		|| (
			((n % 100) >= 1 && (n % 100) <= 4)
			|| ((n % 100) >= 21 && (n % 100) <= 24)
			|| ((n % 100) >= 41 && (n % 100) <= 44)
			|| ((n % 100) >= 61 && (n % 100) <= 64)
			|| ((n % 100) >= 81 && (n % 100) <= 84)
		)
	):
		return PluralCase.One
	if n == 5 || n % 100 == 5:
		return PluralCase.Many

	return PluralCase.Other


# get the ordinal plural case depending on the locale passed in
func __get_ordinal_case_49(value: float) -> int:
	var v := int(ceil(abs(value)))

	# printerr("v:%s value:%s" % [v, value])

	if (v % 10 == 1) && !(v % 100 == 11):
		return PluralCase.One
	if (v % 10 == 2) && !(v % 100 == 12):
		return PluralCase.Two
	if (v % 10 == 3) && !(v % 100 == 13):
		return PluralCase.Few

	return PluralCase.Other


func __get_ordinal_case_50(value: float) -> int:
	var n := int(abs(value))
	if n == 1:
		return PluralCase.One

	if n == 2 || n == 3:
		return PluralCase.Two
	if n == 4:
		return PluralCase.Few
	return PluralCase.Other


func __get_ordinal_case_51(value: float) -> int:
	var n := int(abs(value))

	if n == 1 || n == 11:
		return PluralCase.One
	if n == 2 || n == 12:
		return PluralCase.Two
	if n == 3 || n == 13:
		return PluralCase.Few

	return PluralCase.Other


func __get_ordinal_case_52(value: float) -> int:
	var n := int(abs(value))
	if n == 1 || n == 3:
		return PluralCase.One
	if n == 2:
		return PluralCase.Two
	if n == 4:
		return PluralCase.Few

	return PluralCase.Other


func __get_ordinal_case_53(value: float) -> int:
	var i := int(value)

	if i % 10 == 1 && !(i % 100 == 11):
		return PluralCase.One
	if i % 10 == 2 && !(i % 100 == 12):
		return PluralCase.Two
	if ((i % 10) == 7) || ((i % 10) == 8) && !(((i % 100) == 17) || ((i % 100) == 18)):
		return PluralCase.Many

	return PluralCase.Other


func __get_ordinal_case_54(value: float) -> int:
	var i := int(value)
	if (
		(
			((i % 10) == 1)
			|| ((i % 10) == 2)
			|| ((i % 10) == 5)
			|| ((i % 10) == 7)
			|| ((i % 10) == 8)
		)
		|| (((i % 100) == 20) || ((i % 100) == 50) || ((i % 100) == 70) || ((i % 100) == 80))
	):
		return PluralCase.One
	if (
		(((i % 10) == 3) || ((i % 10) == 4))
		|| (
			((i % 1000) == 100)
			|| ((i % 1000) == 200)
			|| ((i % 1000) == 300)
			|| ((i % 1000) == 400)
			|| ((i % 1000) == 500)
			|| ((i % 1000) == 600)
			|| ((i % 1000) == 700)
			|| ((i % 1000) == 800)
			|| ((i % 1000) == 900)
		)
	):
		return PluralCase.Few
	if (i == 0) || ((i % 10) == 6) || (((i % 100) == 40) || ((i % 100) == 60) || ((i % 100) == 90)):
		return PluralCase.Many
	return PluralCase.Other


func __get_ordinal_case_55(value: float) -> int:
	var n := int(abs(value))
	if n == 1:
		return PluralCase.One
	if n == 2 || n == 3:
		return PluralCase.Two
	if n == 4:
		return PluralCase.Few
	if n == 6:
		return PluralCase.Many

	return PluralCase.Other


func __get_ordinal_case_56(value: float) -> int:
	var n := int(abs(value))
	if (n == 1) || (n == 5) || (n == 7) || (n == 8) || (n == 9) || (n == 10):
		return PluralCase.One
	if n == 2 || n == 3:
		return PluralCase.Two
	if n == 4:
		return PluralCase.Few
	if n == 6:
		return PluralCase.Many
	return PluralCase.Other


func __get_ordinal_case_57(value: float) -> int:
	var n := int(abs(value))
	if n == 1 || n == 5 || (n >= 7 && n <= 9):
		return PluralCase.One
	if n == 2 || n == 3:
		return PluralCase.Two
	if n == 4:
		return PluralCase.Few
	if n == 6:
		return PluralCase.Many

	return PluralCase.Other


func __get_ordinal_case_58(value: float) -> int:
	var n := int(abs(value))

	if n == 0 || n == 7 || n == 8 || n == 9:
		return PluralCase.Zero
	if n == 1:
		return PluralCase.One
	if n == 2:
		return PluralCase.Two
	if n == 3 || n == 4:
		return PluralCase.Few
	if n == 5 || n == 6:
		return PluralCase.Many
	return PluralCase.Other


func get_ordinal_case(locale: String, value: float) -> int:
	match locale:
		"af", "am", "an", "ar", "bg", "bs", "ce", "cs", "da", "de", "dsb", "el", "es", "et", "eu", "fa", "fi", "fy", "gl", "gsw", "he", "hr", "hsb", "ia", "id", "in", "is", "iw", "ja", "km", "kn", "ko", "ky", "lt", "lv", "ml", "mn", "my", "nb", "nl", "pa", "pl", "prg", "ps", "pt", "root", "ru", "sd", "sh", "si", "sk", "sl", "sr", "sw", "ta", "te", "th", "tr", "ur", "uz", "yue", "zh", "zu":
			return __get_ordinal_case_36(value)
		"sv":
			return __get_ordinal_case_37(value)
		"fil", "fr", "ga", "hy", "lo", "mo", "ms", "ro", "tl", "vi":
			return __get_ordinal_case_38(value)
		"hu":
			return __get_ordinal_case_39(value)
		"ne":
			return __get_ordinal_case_40(value)
		"be":
			return __get_ordinal_case_41(value)
		"uk":
			return __get_ordinal_case_42(value)
		"tk":
			return __get_ordinal_case_43(value)
		"kk":
			return __get_ordinal_case_44(value)
		"it", "sc", "scn":
			return __get_ordinal_case_45(value)
		"ka":
			return __get_ordinal_case_46(value)
		"sq":
			return __get_ordinal_case_47(value)
		"kw":
			return __get_ordinal_case_48(value)
		"en":
			return __get_ordinal_case_49(value)
		"mr":
			return __get_ordinal_case_50(value)
		"gd":
			return __get_ordinal_case_51(value)
		"ca":
			return __get_ordinal_case_52(value)
		"mk":
			return __get_ordinal_case_53(value)
		"az":
			return __get_ordinal_case_54(value)
		"gu", "hi":
			return __get_ordinal_case_55(value)
		"as", "bn":
			return __get_ordinal_case_56(value)
		"or":
			return __get_ordinal_case_57(value)
		"cy":
			return __get_ordinal_case_58(value)
		_:
			pass

	return PluralCase.NoPluralisation


# get an integer representation of what is after the dot in a float value
#
# get_fraction (5.67)    -> 67
# get_fraction (0.00005) -> 5
func get_fraction(value: float) -> int:
	var e = step_decimals(value)
	var v = value - int(value)
	return int(v * pow(10, e))
