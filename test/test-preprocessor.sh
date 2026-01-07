#!/bin/bash

PACKAGE_NAME="$(cat ../bin/pkgname.cfg)"

LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
NC='\033[0m'

TEST_DIR="${PWD}/tests/preprocessor"
TEST_SRC="${TEST_DIR}/preprocessor"

function file () {
    FILE=${1%.*}
    if [ -f "${FILE}" ]; then rm ${FILE}; fi
    echo "${FILE}"
}

function total () {
    echo "----------------------------------------------------------------------"
    RESULT="${PASS} / ${TOTAL}"
    if [ ${PASS} -eq ${TOTAL} ]; then
        RESULT="${LIGHT_GREEN}PASS: ${RESULT}${NC}"
        RETURN=0
    else
        RESULT="${LIGHT_RED}FAIL: ${RESULT}${NC}"
        RETURN=1
    fi
    echo -e "${RESULT}"
}

function indent () {
    echo -n "$(echo "${TOTAL} [ ] ${FILE}.c" | sed -r 's/./ /g')"
}

function print_check () {
    echo " - check ${1} -> ${2}"
}

function print_success () {
    echo -e -n "${TOTAL} ${RESULT} ${FILE}.c${NC}"
    PRINT="${PACKAGE_NAME}: ${RETURN}"
    print_check "return" "[${PRINT}]"
    if [ ! -z "${STDOUT}" ]; then
        indent
        PRINT=$(echo "${PACKAGE_NAME}:"; echo ${STDOUT})
        print_check "stdout" "[${PRINT}]"
    fi
}

function print_error () {
    echo -e -n "${TOTAL} ${RESULT} ${FILE}.c${NC}"
    PRINT=$(echo "${PACKAGE_NAME}:"; echo "${STDOUT}")
    print_check "error" "[${PRINT}]"
}

function check_success () {
    let TOTAL+=1

    STDOUT=""
    if [ ${RETURN} -ne 0 ]; then
        RESULT="${LIGHT_RED}[n]"
    else
        STDOUT=$(${FILE} ${@} 2>&1)
        RETURN=${?}
        rm ${FILE}

        if [ ${RETURN} -eq ${CHECK_VAL} ]; then
            if [[ "${STDOUT}" == "${CHECK_STR}" ]]; then
                RESULT="${LIGHT_GREEN}[y]"
                let PASS+=1
            else
                RESULT="${LIGHT_RED}[n]"
            fi
        else
            RESULT="${LIGHT_RED}[n]"
        fi
    fi

    print_success
}

function check_hallo_welt () {
    cd ${TEST_SRC}/hallo_welt
    FILE=$(file ${PWD}/haupt.c)

    CHECK_STR="Hallo Welt!"
    for i in $(seq 1 2); do
        ${PACKAGE_NAME} -E -Ibibliothek/ ${FILE}.c > /dev/null 2>&1
        RETURN=${?}
        if [ ${i} -eq 1 ]; then
            CHECK_VAL=0; check_success
        else
            CHECK_VAL=42; check_success 42
        fi

        ${PACKAGE_NAME} -E -DProgrammierschnittstelle \
            -DGanz=int -DZeichen=char -Dwenn=if -Dzuruck=return \
            -Ibibliothek/ ${FILE}.c > /dev/null 2>&1
        RETURN=${?}
        if [ ${i} -eq 1 ]; then
            CHECK_VAL=0; check_success
        else
            CHECK_VAL=42; check_success 42
        fi
    done
}

function check_compiler_tests () {
    COUNT_I=0; COUNT_S=0; CHECK_VAL=0
    FILES="$(find $(readlink -f ${TEST_DIR}/../compiler) -name "*.c" -type f |\
         grep --invert-match invalid | sort --uniq)"
    for FILE in ${FILES}; do
        FILE=$(file ${FILE})
        if [ -f "${FILE}.i" ]; then
            rm "${FILE}.i"
        fi
        if [ -f "${FILE}.s" ]; then
            rm "${FILE}.s"
        fi
        ${PACKAGE_NAME} -E -S ${FILE}.c > /dev/null 2>&1
        RETURN=${?}
        if [ ${RETURN} -ne 0 ]; then
            RETURN=1
        fi
        if [ -f "${FILE}.i" ]; then
            let COUNT_I+=1
            rm "${FILE}.i"
        else
            RETURN=2
        fi
        if [ -f "${FILE}.s" ]; then
            let COUNT_S+=1
            rm "${FILE}.s"
        else
            RETURN=3
        fi
        if [ ${RETURN} -eq 0 ]; then
            let CHECK_VAL+=1
        fi
    done

    STDOUT=""
    RETURN=$(echo "${FILES}" | wc -l | tr -d ' ')
    CHECK_STR="${RETURN}/${RETURN}"

    OUT_FILE="${TEST_SRC}/check_i.c"
    echo "int puts(char* s);" > ${OUT_FILE}
    echo "int main(void) {" >> ${OUT_FILE}
    echo "    puts(\"${COUNT_I}/${RETURN}\");" >> ${OUT_FILE}
    echo "    if (${COUNT_I} == ${RETURN} && ${CHECK_VAL} == ${RETURN}) {" >> ${OUT_FILE}
    echo "        return 0;" >> ${OUT_FILE}
    echo "    }" >> ${OUT_FILE}
    echo "    return 1;" >> ${OUT_FILE}
    echo "}" >> ${OUT_FILE}

    OUT_FILE="${TEST_SRC}/check_s.c"
    echo "int puts(char* s);" > ${OUT_FILE}
    echo "int main(void) {" >> ${OUT_FILE}
    echo "    puts(\"${COUNT_S}/${RETURN}\");" >> ${OUT_FILE}
    echo "    if (${COUNT_S} == ${RETURN} && ${CHECK_VAL} == ${RETURN}) {" >> ${OUT_FILE}
    echo "        return 0;" >> ${OUT_FILE}
    echo "    }" >> ${OUT_FILE}
    echo "    return 1;" >> ${OUT_FILE}
    echo "}" >> ${OUT_FILE}

    FILE=$(file ${TEST_SRC}/check_i.c)
    ${PACKAGE_NAME} -E ${FILE}.c > /dev/null 2>&1
    RETURN=${?}
    CHECK_VAL=0; check_success

    FILE=$(file ${TEST_SRC}/check_s.c)
    ${PACKAGE_NAME} -E ${FILE}.c > /dev/null 2>&1
    RETURN=${?}
    CHECK_VAL=0; check_success
}

function check_macros_with_cpp () {
    TEST_SRC="${TEST_DIR}/macros_with_cpp"
    check_hallo_welt
    check_compiler_tests
}

function get_header_dir () {
    HEADER_DIR=""
    for i in $(seq 1 ${1}); do
        HEADER_DIR="${HEADER_DIR}${i}/"
    done
    mkdir -p ${TEST_SRC}/${HEADER_DIR}
    echo "${HEADER_DIR}"
}

function check_includes () {
    N=${1}
    for i in $(seq 1 2); do
        let TOTAL+=1

        if [ ${i} -eq 1 ]; then
            ${PACKAGE_NAME} -I${TEST_SRC} ${FILE}.c > /dev/null 2>&1
            RETURN=${?}
        else
            ${PACKAGE_NAME} -E -DWITH_FLAG_E -I${TEST_SRC} ${FILE}.c > /dev/null 2>&1
            RETURN=${?}
        fi
        STDOUT=""
        if [ ${RETURN} -ne 0 ]; then
            RESULT="${LIGHT_RED}[n]"
        else
            STDOUT=$(${FILE})
            RETURN=${?}
            rm ${FILE}

            diff -sq <(echo "${STDOUT}") <(
                for i in $(seq 1 $((${N}+1))); do
                    echo "Hello ${i}!"
                done
            ) | grep -q "identical"
            if [ ${?} -eq 0 ]; then
                if [ ${RETURN} -eq $((${N}+1)) ]; then
                    RESULT="${LIGHT_GREEN}[y]"
                    let PASS+=1
                else
                    RESULT="${LIGHT_RED}[n]"
                fi
            else
                RESULT="${LIGHT_RED}[n]"
            fi
        fi

        print_success
    done
}

function check_error () {
    ERR=${1}
    OUT_FILE="${TEST_SRC}/$(get_header_dir ${ERR})test-header_${ERR}.h"
    echo "int e1 = {0, 1, 2};" >> ${OUT_FILE}
    for i in $(seq 1 2); do
        let TOTAL+=1

        if [ -f "${FILE}" ]; then
            rm ${FILE}
        fi
        if [ -f "${FILE}.i" ]; then
            rm ${FILE}.i
        fi

        if [ ${i} -eq 1 ]; then
            STDOUT=$(${PACKAGE_NAME} -I${TEST_SRC} ${FILE}.c 2>&1)
            RETURN=${?}
        else
            STDOUT=$(${PACKAGE_NAME} -E -DWITH_FLAG_E -I${TEST_SRC} ${FILE}.c 2>&1)
            RETURN=${?}
        fi
        if [ ${RETURN} -eq 0 ]; then
            rm ${FILE}
            RESULT="${LIGHT_RED}[n]"
        else
            if [ ${i} -eq 1 ]; then
                diff -sq <(echo "${STDOUT}") <(
                    echo -e -n "\033[1m${TEST_SRC}/"
                    for j in $(seq 1 $((${ERR}))); do
                        echo -n "${j}/"
                    done
                    echo -e "test-header_${ERR}.h:9:11:${NC}"
                    echo -e "\033[0;31merror:${NC} (no. 547) cannot initialize scalar type \033[1m‘int’${NC} with compound initializer"
                    echo -e "at line 9: \033[0;31m          v${NC}"
                    echo -e "         | \033[1mint e1 = {0, 1, 2};${NC}"
                    echo -e "${PACKAGE_NAME}: \033[0;31merror:${NC} compilation failed, see \033[1m‘--help’${NC}"
                ) | grep -q "identical"
                if [ ${?} -eq 0 ]; then
                    RESULT="${LIGHT_GREEN}[y]"
                    let PASS+=1
                else
                    RESULT="${LIGHT_RED}[n]"
                fi
            else
                if [ -f "${FILE}.i" ]; then
                    rm ${FILE}.i
                    RESULT="${LIGHT_GREEN}[y]"
                    let PASS+=1
                else
                    RETURN=1
                    STDOUT="File ${FILE}.i not found"
                    RESULT="${LIGHT_RED}[n]"
                fi
            fi
        fi

        print_error
    done
}

function check_preprocessor () {
    cd ${TEST_DIR}
    TEST_SRC="${TEST_DIR}/preprocessor"
    FILE=$(file ${TEST_SRC}/main.c)

    N=63
    ERR=27
    DEF_WITH_CPP="WITH_FLAG_E"

    if [ -d "${TEST_SRC}" ]; then
        rm -r ${TEST_SRC}
    fi
    mkdir -p ${TEST_SRC}

    echo -n "" > ${TEST_SRC}/test-header_0.h

    OUT_FILE="${TEST_SRC}/test-define_0.h"

    echo "#pragma once" > ${OUT_FILE}
    echo "#define DEF_STR(X) s##X = \"Hello \" #X \"!\"" >> ${OUT_FILE}

    for i in $(seq 1 $((N-1))); do
        OUT_FILE="${TEST_SRC}/$(get_header_dir ${i})test-header_${i}.h"
        echo "#pragma once" > ${OUT_FILE}
        echo "int x${i} = 1;" >> ${OUT_FILE}
        echo "// a single-line comment ${i}" >> ${OUT_FILE}
        echo "#include \"$(get_header_dir $((${N}-${i})))test-header_$((${N}-${i})).h\"" >> ${OUT_FILE}
        echo "/* a multi-line" >> ${OUT_FILE}
        echo "  comment ${i}" >> ${OUT_FILE}
        echo "  */" >> ${OUT_FILE}
        echo "char* s${i} = 0;" >> ${OUT_FILE}

        OUT_FILE="${TEST_SRC}/$(get_header_dir ${i})test-define_${i}.h"
        echo "#pragma once" > ${OUT_FILE}
        echo "#define STR_${i} DEF_STR(${i})" >> ${OUT_FILE}
        echo "#ifndef ${DEF_WITH_CPP}" >> ${OUT_FILE}
        echo "char* STR_${i} = \"Hello ${i}!\";" >> ${OUT_FILE}
        echo "#endif" >> ${OUT_FILE}
    done

    OUT_FILE="${TEST_SRC}/test-header_${N}.h"
    echo "#pragma once" > ${OUT_FILE}
    echo "int x${N} = 1;" >> ${OUT_FILE}
    echo "// a single-line comment ${N}" >> ${OUT_FILE}
    echo "#include \"test-header_0.h\"" >> ${OUT_FILE}
    echo "/* a multi-line" >> ${OUT_FILE}
    echo "  comment ${N}" >> ${OUT_FILE}
    echo "  */" >> ${OUT_FILE}
    echo "char* s${N} = 0;" >> ${OUT_FILE}

    OUT_FILE="${TEST_SRC}/test-define_${N}.h"
    echo "#pragma once" > ${OUT_FILE}
    echo "#include \"test-define_0.h\"" >> ${OUT_FILE}
    echo "#define STR_${N} DEF_STR(${N})" >> ${OUT_FILE}
    echo "#ifndef ${DEF_WITH_CPP}" >> ${OUT_FILE}
    echo "char* STR_${N} = \"Hello ${N}!\";" >> ${OUT_FILE}
    echo "#endif" >> ${OUT_FILE}

    OUT_FILE="${FILE}.c"
    echo "int puts(char* s);" > ${OUT_FILE}
    echo "" >> ${OUT_FILE}
    echo "int x$((${N}+1)) = 1;" >> ${OUT_FILE}
    echo "// a single-line comment $((${N}+1))" >> ${OUT_FILE}
    echo "" >> ${OUT_FILE}
    echo "#define STR_$((${N}+1)) DEF_STR($((${N}+1)))" >> ${OUT_FILE}
    echo "#ifndef ${DEF_WITH_CPP}" >> ${OUT_FILE}
    echo "char* STR_$((${N}+1)) = \"Hello $((${N}+1))!\";" >> ${OUT_FILE}
    echo "#endif" >> ${OUT_FILE}
    echo "#include \"test-define_${N}.h\"" >> ${OUT_FILE}
    for i in $(seq 1 $((N-1))); do
        echo "#include \"$(get_header_dir ${i})test-define_${i}.h\"" >> ${OUT_FILE}
        echo "#include \"$(get_header_dir ${i})test-header_${i}.h\"" >> ${OUT_FILE}
    done
    echo "#include \"test-header_${N}.h\"" >> ${OUT_FILE}
    echo "" >> ${OUT_FILE}
    echo "/* a multi-line" >> ${OUT_FILE}
    echo "  comment $((${N}+1))" >> ${OUT_FILE}
    echo "  */" >> ${OUT_FILE}
    echo "char* s$((${N}+1)) = 0;" >> ${OUT_FILE}
    echo "" >> ${OUT_FILE}
    echo "int main(void) {" >> ${OUT_FILE}
    for i in $(seq 1 $((${N}+1))); do
        echo "    s${i} = STR_${i};" >> ${OUT_FILE}
    done
    for i in $(seq ${k} $((${N}+1))); do
        echo "    puts(s${i});" >> ${OUT_FILE}
    done
        echo "    return 0" >> ${OUT_FILE};
    for i in $(seq 1 $((${N}+1))); do
        echo "    + x${i}" >> ${OUT_FILE}
    done
    echo "    ;" >> ${OUT_FILE}
    echo "}" >> ${OUT_FILE}

    check_includes ${N}
    check_error ${ERR}
}

PASS=0
TOTAL=0
RETURN=0
check_macros_with_cpp
check_preprocessor
total

exit ${RETURN}
