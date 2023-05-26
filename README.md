# subdomain-enum1.sh

last one use only 3 tool [amass, subfinder, httprobe] , in this script waybackurls added make easy to save time. when waybackurls task end it result save as 4-wayback-result.txt.

how to use: 
subdomain-enum.sh doamins.txt 

copy the code give permission by chmod +x subdomain-enum.sh and move it to bin folder. 


this is a automated tool it work all the task given below. before use this tool make sure you install all required tool to work without any error. any 
how it works-
1. make a parent directory by doamin name 
2. run amass and subfinder 
3 combine both result in one new file name 2-all-domain_name.txt [dublicate domain remove]
4. it take previous result and use httprobe tool and save as 3-sub_domain_name.txt
5. after it use waybackurls tool and save the result as 4-wayback-result.txt
