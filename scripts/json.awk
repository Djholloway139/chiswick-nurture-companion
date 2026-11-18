# Strict JSON parser for transport envelopes. Product policy does not belong here.
function fail() { bad=1; exit 1 }
function ws() { while(p<=length(s) && substr(s,p,1) ~ /^[ \t\r\n]$/) p++ }
function str(    c,v,e,i) {
  if(substr(s,p++,1)!="\"") fail()
  v=""
  while(p<=length(s)) {
    c=substr(s,p++,1)
    if(c=="\"") return v
    if(c ~ /[[:cntrl:]]/) fail()
    if(c=="\\") {
      e=substr(s,p++,1)
      if(e=="u") {
        # Shell command extraction accepts literal text and escaped quotes,
        # slashes and backslashes. Refuse other escapes rather than alter them.
        if(mode=="string-at-path") fail()
        for(i=0;i<4;i++) if(substr(s,p+i,1)!~/^[0-9a-fA-F]$/) fail()
        v=v "\\u" substr(s,p,4); p+=4
      } else {
        if(e!~/^["\\\/bfnrt]$/) fail()
        if(mode=="string-at-path") {
          if(e!~/^["\\\/]$/) fail()
          v=v e
        }
        else if(e=="n" || e=="r" || e=="t") v=v " "
        else v=v "\\" e
      }
    } else v=v c
  }
  fail()
}
function value(path,depth,    c,key,n,t,oid) {
  if(depth>100) fail()
  ws(); c=substr(s,p,1)
  if(c=="{") {
    oid=++objects; types[path]="object"
    p++; ws(); if(substr(s,p,1)=="}"){p++;return}
    while(1) {
      ws(); key=str()
      if(seen[oid SUBSEP key]++) fail()
      gsub(/~/,"~0",key); gsub(/\//,"~1",key)
      ws(); if(substr(s,p++,1)!=":") fail()
      value(path "/" key,depth+1); ws(); c=substr(s,p++,1)
      if(c=="}") return
      if(c!=",") fail()
    }
  }
  if(c=="[") {
    types[path]="array"; p++; n=0; ws()
    if(substr(s,p,1)=="]") p++
    else while(1) {
      value(path "/" n,depth+1); n++; ws(); c=substr(s,p++,1)
      if(c=="]") break
      if(c!=",") fail()
    }
    sizes[path]=n; return
  }
  if(c=="\"") { vals[path]=str(); types[path]="string"; return }
  t=substr(s,p)
  if(match(t,/^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?/)) {
    vals[path]=substr(t,1,RLENGTH); types[path]="number"; p+=RLENGTH;return
  }
  if(substr(t,1,4)=="true" || substr(t,1,4)=="null") {
    vals[path]=substr(t,1,4); types[path]=vals[path]; p+=4; return
  }
  if(substr(t,1,5)=="false") { vals[path]="false";types[path]="false";p+=5;return }
  fail()
}
{ s=s $0 "\n" }
END {
  if(bad) exit 1
  if(mode=="hook-session" && s ~ /^[ \t\r\n]*$/) { print "fallback"; exit }
  p=1; value("",0); ws()
  if(p<=length(s)) exit 1
  if(mode=="string-at-path") {
    if(types[target_path]!="string" || vals[target_path]=="") exit 1
    print vals[target_path]
  }
  if(mode=="object-member") {
    if(types[""]!="object" || types["/" member]=="") exit 1
  }
  if(mode=="hook-session") {
    if(types[""]!="object") exit 1
    if(types["/session_id"]=="") print "fallback"
    else {
      sid=vals["/session_id"]
      if(types["/session_id"]!="string" || length(sid)>128 || sid !~ /^[a-zA-Z0-9_-]+$/) exit 1
      print "sid-" sid
    }
  }
  if(mode=="discovery") {
    if(types[""]!="object" || types["/jsonrpc"]!="string" || vals["/jsonrpc"]!="2.0" ||
       types["/id"]!="number" || vals["/id"]!="1" || types["/error"]!="" ||
       types["/result"]!="object" || types["/result/tools"]!="array") exit 1
    n=sizes["/result/tools"]
    for(i=0;i<n;i++) {
      base="/result/tools/" i
      if(types[base "/name"]!="string" || types[base "/description"]!="string" ||
         types[base "/inputSchema"]!="object") exit 1
    }
    if(types["/result/nextCursor"]!="" && types["/result/nextCursor"]!="null") print "partial"
    else print n
  }
  if(mode=="error") {
    if(types["/error"]=="string") print vals["/error"]
    else if(types["/error/message"]=="string") print vals["/error/message"]
    else if(vals["/result/isError"]=="true" &&
            types["/result/content/0/text"]=="string") print vals["/result/content/0/text"]
    else exit 1
  }
}
