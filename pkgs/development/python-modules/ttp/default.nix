{
  lib,
  buildPythonPackage,
  cerberus,
  configparser,
  deepdiff,
  fetchFromGitHub,
  geoip2,
  jinja2,
  netmiko,
  openpyxl,
  pytestCheckHook,
  poetry-core,
  pyyaml,
  tabulate,
  ttp-templates,
  yangson,
}:

buildPythonPackage rec {
  pname = "ttp";
  version = "0.9.5";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "dmulyalin";
    repo = "ttp";
    tag = version;
    hash = "sha256-IWqPFspERBVkjsTYTAkOTOrugq4fD65Q140G3SCEV0w=";
  };

  nativeBuildInputs = [ poetry-core ];

  propagatedBuildInputs = [
    # https://github.com/dmulyalin/ttp/blob/master/docs/source/Installation.rst#additional-dependencies
    cerberus
    configparser
    deepdiff
    geoip2
    jinja2
    # n2g unpackaged
    netmiko
    # nornir unpackaged
    openpyxl
    tabulate
    yangson
  ];

  pythonImportsCheck = [ "ttp" ];

  nativeCheckInputs = [
    pytestCheckHook
    pyyaml
    ttp-templates
  ];

  disabledTestPaths = [
    # missing package n2g
    "test/pytest/test_N2G_formatter.py"
    # missing test file
    "test/pytest/test_extend_tag.py"
    "test/pytest/test_ttp_parser_methods.py"
  ];

  disabledTests = [
    # data structure mismatches
    "test_global_output_deepdiff_with_var_before"
    "test_group_specific_output_deepdiff_with_var_before"
    "test_group_specific_output_deepdiff_with_var_before_with_add_field"
    "test_yangson_validate"
    "test_yangson_validate_yang_lib_in_output_tag_data"
    "test_yangson_validate_multiple_inputs_mode_per_input_with_yang_lib_in_file"
    "test_yangson_validate_multiple_inputs_mode_per_template"
    "test_yangson_validate_multiple_inputs_mode_per_input_with_yang_lib_in_file_to_xml"
    "test_yangson_validate_multiple_inputs_mode_per_template_to_xml"
    "test_adding_data_from_files"
    "test_lookup_include_csv"
    "test_inputs_with_template_base_path"
    "test_group_inputs"
    "test_inputs_url_filters_extensions"
    # ValueError: dictionary update sequence element #0 has length 1; 2 is required
    "test_include_attribute_with_yaml_loader"
    # TypeError: string indices must be integers
    "test_lookup_include_yaml"
    # Missing .xslx files *shrug*
    "test_excel_formatter_update"
    "test_excel_formatter_update_using_result_kwargs"
    # missing package n2g
    "test_n2g_formatter"
    # missing test files
    "test_TTP_CACHE_FOLDER_env_variable_usage"
    # requires additional network setup
    "test_child_group_do_not_start_if_no_parent_started"
    # Assertion Error
    "test_in_threads_parsing"
    # missing env var
    "test_ttp_templates_dir_env_variable"
  ];

  enabledTestPaths = [ "test/pytest" ];

  meta = with lib; {
    changelog = "https://github.com/dmulyalin/ttp/releases/tag/${version}";
    description = "Template Text Parser";
    mainProgram = "ttp";
    homepage = "https://github.com/dmulyalin/ttp";
    license = licenses.mit;
    maintainers = [ ];
  };
}
