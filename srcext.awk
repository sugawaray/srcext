function assert(ok, message) {
	if (!ok)
		print message
}

function output(alist, acount, rlist, rcount) {
	printf "%s:", FILENAME

	for (i = 0; i < acount - 1; ++i)
		printf "%s ", alist[i]
	printf("%s:", alist[i])

	for (i = 0; i < rcount - 1; ++i)
		printf "%s ", rellist[i]
	print sprintf("%s", rellist[i])
}

BEGIN {
	rincpath = "(\"[^\"]+\"|<[^>]+>)"
	rinclude = sprintf("^#include[ \t]+%s", incpath)
	i_abs = 0
	i_rel = 0
}
$0 ~ rinclude {
	p = match($0, rincpath)
	assert(p != 0, sprintf("invalid #include line %d.", NR))
	assert(RLENGTH > 2, sprintf("logic error regex(%s).", rincpath))

	path = substr($0, p + 1, RLENGTH - 2)
	if (substr($0, p, 1) == "\"")
		rellist[i_rel++] = path
	else
		abslist[i_abs++] = path
}
END {
	output(abslist, i_abs, rellist, i_rel)
}
