#!/bin/bash
##
## Copyright 2019 International Business Machines
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##

if [ ! -f ./synset_words.txt ]; then
    wget https://raw.githubusercontent.com/HoldenCaulfieldRye/caffe/master/data/ilsvrc12/synset_words.txt
fi

if [ -z $1 ]; then
    input=output.dimg
else
    input=$1
fi

print_result() {
    echo "Line   Rate    Synset_Word"
    for i in $1; do
        results=`grep -n "^${i}" $input`
        for j in $results; do
            line=`cut -d':' -f1 <<<$j`
            rate=`cut -d':' -f2 <<<$j`
            synset_word=`sed "${line}!d" ./synset_words.txt`
            printf "%4d   %3d      %s\n" "$line" "$rate" "$synset_word"
        done
    done
}

sed -i 's/ /\n/g' $input
max_value=`sort -rn $input | head -5 | uniq`
echo "**** The Top 5 ****"
print_result "$max_value"

echo
echo "**** The Bottom 5 ****"
min_value=`sort -n $input | head -5 | uniq`
print_result "$min_value"

