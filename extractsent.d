#!/usr/bin/dmd
import std.stdio;
import std.string;
import std.process;
import std.algorithm;
import std.array:array;
import std.typecons:Tuple;
import std.file:exists;

alias ProcessResult=Tuple!(int,"status",string[],"emails");
enum whitelistPath="sent_whitelist.txt";

int main(string[] args)
{
	bool all=(args.length==2 && args[1]=="--all");
	string[] emails;
	if (!all && whitelistPath.exists)
		emails=(cast(string)std.file.read(whitelistPath)).
			splitLines.array;
	
	auto results=process("laeeth@laeeth.com",emails,all);
	if(results.status==0)
		return -1;
	results=process("laeeth@kaleidicassociates.com",results.emails,all);
	if (results.status==0)
		return -1;
	writefln("* unique emails =%s",results.emails.length);
	string result;
	foreach(item;results.emails)
		result~=item~"\n";
	std.file.write(whitelistPath,result);
	return 0;
}

	
ProcessResult process(string account,string[] emailList,bool all)
{
	auto cmd=" doveadm fetch -u "~account ~" hdr " ~ (all?" SINCE 01-Jan-2013 ":" SINCE 01-Jan-2016 ")~"mailbox Sent | grep To";
	writefln("* executing %s",cmd);
	auto ret=executeShell(cmd);
	if (ret.status!=0)
	{
		stderr.writefln("Failed to retrieve sent emails");
		stderr.writefln("%s",ret.output);
		return ProcessResult(0,[]);
	}
	writefln("* %s emails extracted",ret.output.splitLines.length);
	foreach(line;ret.output.splitLines)
		emailList~=line.extractEmails;
	writefln("* extracted juice");
	emailList=emailList.sort.uniq.array;
	writefln("* unique emails =%s",emailList.length);
	return ProcessResult(1,emailList);
}

string[] extractEmails(string line)
{
	string[] ret;
	auto i=line.indexOf("<");
	while ((i!=-1)&&(i<line.length-1))
	{
		auto j=line[i+1..$].indexOf(">");
		if ((j==-1)||(i+j+1>=line.length-1))
			break;
		ret~=line[i+1..i+j+1];
		if (j==line.length)
			break;
		auto k=line[i+j+1..$].indexOf("<");
		i=(k==-1)?-1:i+j+1+k+1;
	}
	return ret;
}

