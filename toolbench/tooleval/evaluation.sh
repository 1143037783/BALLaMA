export MODEL_TYPE=qwen3_cot
export TOOL_TYPE=tool
export API_POOL_FILE=../../openai_key.json
export CONVERTED_ANSWER_PATH=../../data/${MODEL_TYPE}/${TOOL_TYPE}/model_predictions_converted
export SAVE_PATH=../../data/${MODEL_TYPE}/${TOOL_TYPE}/pass_rate_results
mkdir -p ${SAVE_PATH}
export CANDIDATE_MODEL=virtual_chatgpt_cot
export EVAL_MODEL=deepseek-chat
#export EVAL_MODEL=openai/gpt-5.1
mkdir -p ${SAVE_PATH}/${CANDIDATE_MODEL}

GROUP_LIST=(
  G1_instruction
  G1_category
  G1_tool
  G2_category
  G2_instruction
  G3_instruction
)

#  G1_instruction
#  G1_category
#  G1_tool
#  G2_category
#  G2_instruction
#  G3_instruction

for group in "${GROUP_LIST[@]}"; do
    echo "===== Running group: $group ====="
    python eval_pass_rate.py \
      --converted_answer_path ${CONVERTED_ANSWER_PATH} \
      --save_path ${SAVE_PATH}/${CANDIDATE_MODEL} \
      --reference_model ${CANDIDATE_MODEL} \
      --test_ids ../../solvable_queries/test_query_ids \
      --max_eval_threads 35 \
      --evaluate_times 3 \
      --test_set ${group}
done