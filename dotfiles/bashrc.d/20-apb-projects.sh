# Bash project switcher (`prj`). Set the projects root if not already set
# (the main bashrc used to set this before sourcing; this snippet is standalone).
: "${APB_PROJECT_DIR:=$HOME/projects}"

function _apb_project-valid_dir ()
{
    if [ -v APB_PROJECT_DIR -a -n "${APB_PROJECT_DIR}" -a -d "${APB_PROJECT_DIR}" ]
    then
        return 0
    fi

    # Invalid
    return 1
}

function _apb-project_current-project ()
{
    local prefix=${PWD:0:${#APB_PROJECT_DIR}}
    if [ x$prefix == x$APB_PROJECT_DIR -a $PWD != $APB_PROJECT_DIR ]
    then
        local proj=${PWD#$APB_PROJECT_DIR}
        proj=${proj#/}
        proj=${proj%%/*}
        echo "$proj"
        return 0
    else
        return 1
    fi
}

function _apb-project_switch-project ()
{
    local proj=$1
    local proj_dir=$APB_PROJECT_DIR/$proj

    if [ -d "$proj_dir" ]
    then
        local CD_PLEASE_BE_SILENT=Y
        cd $proj_dir
        export APB_CURRENT_PROJECT=$proj
        export PHOME=$proj_dir

        local proj_module=$APB_PROJECT_DIR/.modules/projects/$proj
        if [ -e $proj_module ]
        then
            module add projects/$proj
        fi
        return 0
    else
        return 1
    fi
}

function _prj ()
{
    COMPREPLY=()
    local cur=${COMP_WORDS[COMP_CWORD]}

    if [ $COMP_CWORD -gt 1 ]
    then
        return 1
    fi

    if [ ! _apb_project-valid_dir ]
    then
        return 1
    fi

    COMPREPLY=( $(cd ${APB_PROJECT_DIR} && compgen -d -- $cur ) )
    return 0
}

complete -F _prj prj

function prj ()
{
    if [ ! _apb_project-valid_dir ]
    then
        return 1
    fi

    local project=$1

    # No project name specified, show current project.
    if [ -z "${project}" ]
    then
        project=`_apb-project_current-project`
        status=$?
        if [ $status != 0 ]
        then
            echo "No current project"
        else
            echo "Current project: ${project}"
        fi
        return ${status}
    fi

    create_project=no
    if [ "${project:0:1}" == "+" ]
    then
        project=${project:1}
        create_project=yes

        if [ -z "${project}" ]
        then
            echo "Invalid project name: +"
            return 1
        fi
    fi

    # Switch project, handling error case.
    _apb-project_switch-project ${project}
    status=$?
    if [ $status != 0 ]
    then
        if [ $create_project == yes ]
        then
            mkdir $APB_PROJECT_DIR/$project
            status=$?
            if [ $status != 0 ]
            then
                echo "Failed to create project: ${project}"
                return $status
            fi
            _apb-project_switch-project ${project}
            status=$?
        fi

        if [ $status != 0 ]
        then
            echo "No project: ${project}"
            return ${status}
        fi
    fi
    return ${status}
}

MODULEPATH=$APB_PROJECT_DIR/.modules:$MODULEPATH

# Local Variables:
# mode: sh
# End:
