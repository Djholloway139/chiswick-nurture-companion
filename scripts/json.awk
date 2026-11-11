# Strict JSON validation and classification of the fixed task-read key check.
# Usage: awk -f scripts/json.awk file; add -v keycheck=1 for the key-check verdict.
function fail() { bad=1; exit 1 }
function ws() { while (substr(s,p,1) ~ /^[ \t\r\n]$/ && p<=length(s)) p++ }
function str(    c,v,e,i) {
  if (substr(s,p++,1)!="\"") fail()
  v=""
  while (p<=length(s)) {
    c=substr(s,p++,1)
    if (c=="\"") return v
    if (c ~ /[[:cntrl:]]/) fail()
    if (c=="\\") {
      e=substr(s,p++,1)
      if (e=="u") {
        for(i=0;i<4;i++) if(substr(s,p+i,1)!~/^[0-9a-fA-F]$/) fail()
        v=v "\\u" substr(s,p,4); p+=4
      } else { if(e!~/^["\\\/bfnrt]$/) fail(); v=v "\\" e }
    } else v=v c
  }
  fail()
}
function value(path,depth,    c,key,n,t) {
  if(depth>100) fail()
  if(path=="/error") rpcerror=1
  ws(); c=substr(s,p,1)
  if(c=="{") {
    p++; ws(); if(substr(s,p,1)=="}"){p++;return}
    while(1) {
      ws(); key=str(); ws(); if(substr(s,p++,1)!=":") fail()
      value(path "/" key,depth+1); ws(); c=substr(s,p++,1)
      if(c=="}") return
      if(c!=",") fail()
    }
  }
  if(c=="[") {
    p++; n=0; ws()
    if(substr(s,p,1)=="]") p++
    else while(1) {
      value(path "/#",depth+1); n++; ws(); c=substr(s,p++,1)
      if(c=="]") break
      if(c!=",") fail()
      ws()
    }
    return
  }
  if(c=="\"") {
    t=str()
    if(path=="/jsonrpc" && t=="2.0") rpc=1
    if(path=="/result/content/#/type" && t=="text") texttype=1
    if(path=="/result/content/#/text") {
      textfound=1
      if(t ~ /^POD api_v1 returned HTTP 401\./) refused=1
      if(t ~ /^POD api_v1 returned HTTP 403\./) permission=1
    }
    return
  }
  t=substr(s,p)
  if(match(t,/^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?/)) {
    if(path=="/id" && substr(t,1,RLENGTH)=="1") requestid=1
    p+=RLENGTH;return
  }
  if(substr(t,1,4)=="true" || substr(t,1,4)=="null"){
    if(path=="/result/isError" && substr(t,1,4)=="true") iserror=1
    p+=4;return
  }
  if(substr(t,1,5)=="false"){
    if(path=="/result/isError") success=1
    p+=5;return
  }
  fail()
}
{ s=s $0 "\n" }
END {
  if(bad) exit 1
  p=1; value("",0); ws()
  if(p<=length(s)) exit 1
  if(keycheck) {
    if(!rpc || !requestid || rpcerror || !texttype || !textfound || (success && iserror)) exit 1
    if(success) print "accepted"
    else if(iserror && refused && !permission) print "refused"
    else if(iserror && permission && !refused) print "permission"
    else exit 1
  }
}
