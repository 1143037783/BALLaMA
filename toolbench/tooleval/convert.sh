export MODEL_TYPE=qwen3_cot
export TOOL_TYPE=LLM_tool
export RAW_ANSWER_PATH=../../data/${MODEL_TYPE}/${TOOL_TYPE}/answer
export CONVERTED_ANSWER_PATH=../../data/${MODEL_TYPE}/${TOOL_TYPE}/model_predictions_converted
export MODEL_NAME=virtual_chatgpt_cot
export test_set=G1_tool_LLM_tool

mkdir -p ${CONVERTED_ANSWER_PATH}/${MODEL_NAME}
answer_dir=${RAW_ANSWER_PATH}/${MODEL_NAME}/${test_set}
output_file=${CONVERTED_ANSWER_PATH}/${MODEL_NAME}/${test_set}.json

python convert_to_answer_format.py\
    --answer_dir ${answer_dir} \
    --method CoT@1 \
    --output ${output_file}

