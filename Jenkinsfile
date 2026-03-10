pipeline{
    agent {label 'flyway'}
    environment{
        FLYWAY_HOME = '/opt/flyway'
        WORKSPACE_DIR = "${WORKSPACE}"
        FLYWAY_SQL_DIR = "${WORKSPACE}/fly_way_sql"
        FLYWAY_SNAPSHOT = "${WORKSPACE}/flyway_snapshot"
        DB_CREDENTIAL_ID = 'db-credentials'
        GIT_REPO_URL       = 'https://github.com/Hritick-9/sql_flyway'      
        GIT_BRANCH         = 'main'                                 
        GIT_CREDENTIAL_ID  = 'git-credentials-id'                 
        DB_HOST            = '127.0.0.1'                        
        DB_PORT            = '3306'                                 
        DB_NAME            = 'mydb'                  
                        
        UNDO_SCRIPT_DIR    = "${WORKSPACE}/undo_scripts"  
    }
    stages {
       stage('Fetch DB Credentials') {
            steps {
                script {
                    echo "========== STAGE 1: Fetching DB Credentials =========="
                    withCredentials([usernamePassword(
                        credentialsId: "${DB_CREDENTIAL_ID}",
                        usernameVariable: 'DB_USERNAME',
                        passwordVariable: 'DB_PASSWORD'
                    )]) {
                        // Store credentials as environment variables for use in later stages
                        env.DB_USER = DB_USERNAME
                        env.DB_PASS = DB_PASSWORD
                        echo " DB Credentials fetched successfully for user: ${env.DB_USER}"
                    }
                }
            }
        }
        
        stage('Git Checkout') {
            steps {
                script {
                    echo "========== STAGE 2: Git Checkout =========="
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "*/${GIT_BRANCH}"]],
                        userRemoteConfigs: [[
                            url: "${GIT_REPO_URL}",
                         
                        ]]
                    ])
                    echo "Git checkout completed from branch: ${GIT_BRANCH}"
                }
            }
        }

         stage('Create Workspace Directories') {
            steps {
                script {
                    echo "========== STAGE 3: Creating Workspace Directories =========="

                    // Create fly_way_sql directory if it doesn't exist
                    sh """
                        mkdir -p ${FLYWAY_SQL_DIR}
                        echo "Created directory: ${FLYWAY_SQL_DIR}"
                    """

                    // Create flyway_snapshot directory if it doesn't exist
                    sh """
                        mkdir -p ${FLYWAY_SNAPSHOT}
                        echo "Created directory: ${FLYWAY_SNAPSHOT}"
                    """

                    // Create undo scripts directory
                    sh """
                        mkdir -p ${UNDO_SCRIPT_DIR}
                        echo "Created directory: ${UNDO_SCRIPT_DIR}"
                    """

                    // Copy SQL scripts from checkout to fly_way_sql directory
                    sh """
                        cp -r ${WORKSPACE}/sql/* ${FLYWAY_SQL_DIR}/ || true
                        echo "SQL scripts copied to ${FLYWAY_SQL_DIR}"
                        ls -la ${FLYWAY_SQL_DIR}
                    """
                }
            }
        }
       
       
       stage('Remove Carriage Return and Add V Tag') {
            steps {
                script {
                    echo "========== STAGE 4: Remove Carriage Return & Add V Tag =========="

                    sh """
                        #!/bin/bash
                        set -e

                        echo "--- Removing carriage returns from SQL files ---"
                        # Loop through all .sql files and remove carriage returns (\r)
                        find ${FLYWAY_SQL_DIR} -type f -name "*.sql" | while read file; do
                            sed -i 's/\r//g' "\$file"
                            echo "Removed carriage return from: \$file"
                        done

                        echo "--- Adding V tag to SQL scripts ---"
                        # Counter for versioning scripts that don't have V prefix
                        counter=1

                        # Loop through all .sql files and add V tag if not already present
                        for file in \$(ls ${FLYWAY_SQL_DIR}/*.sql | sort); do
                            filename=\$(basename "\$file")

                            # Check if file already has Flyway V prefix (e.g., V1__, V2__)
                            if [[ "\$filename" != V* ]]; then
                                # Generate version tag and rename file with V prefix
                                new_name="V\${counter}__\${filename}"
                                mv "\$file" "${FLYWAY_SQL_DIR}/\${new_name}"
                                echo "Renamed: \$filename -> \${new_name}"
                                counter=\$((counter + 1))
                            else
                                echo "Skipped (already has V tag): \$filename"
                                counter=\$((counter + 1))
                            fi
                        done

                        echo "--- Final SQL files in ${FLYWAY_SQL_DIR} ---"
                        ls -la ${FLYWAY_SQL_DIR}
                    """
                }
            }
        } 
        
        stage('Take Pre-Migration DB Snapshot') {
            steps {
                script {
                    echo "========== STAGE 5: Taking Pre-Migration DB Snapshot =========="

                    sh """
                        #!/bin/bash
                        set -e

                        PRE_SNAPSHOT_FILE="${FLYWAY_SNAPSHOT}/pre_migration_snapshot_\$(date +%Y%m%d_%H%M%S).sql"

                        echo "--- Taking pre-migration snapshot of database: ${DB_NAME} ---"

                        # Using mysqldump to take snapshot of SingleStore DB
                        mysqldump \
                            -h ${DB_HOST} \
                            -P ${DB_PORT} \
                            -u ${env.DB_USER} \
                            -p${env.DB_PASS} \
                            --no-data \
                            --routines \
                            --triggers \
                            ${DB_NAME} > \$PRE_SNAPSHOT_FILE

                        echo "Pre-migration snapshot saved at: \$PRE_SNAPSHOT_FILE"
                        ls -lh \$PRE_SNAPSHOT_FILE

                        # Save snapshot filename for later reference
                        echo \$PRE_SNAPSHOT_FILE > ${FLYWAY_SNAPSHOT}/pre_snapshot_path.txt
                    """
                }
            }
        }
        
// Update Stage 6 in pipeline
// Add a check before running baseline

stage('Flyway Baseline') {
    steps {
        script {
            echo "========== STAGE 6: Flyway Baseline =========="

            sh """
                #!/bin/bash
                set -e

                # Check if flyway_schema_history already exists
                TABLE_EXISTS=\$(mysql \
                    -h ${DB_HOST} \
                    -P ${DB_PORT} \
                    -u ${env.DB_USER} \
                    -p${env.DB_PASS} \
                    -e "SELECT COUNT(*) FROM information_schema.tables \
                        WHERE table_schema='${DB_NAME}' \
                        AND table_name='flyway_schema_history';" \
                    -s --skip-column-names)

                echo "Table exists check: \$TABLE_EXISTS"

                if [ "\$TABLE_EXISTS" -eq "0" ]; then
                    echo "--- flyway_schema_history not found, Running Baseline ---"
                    ${FLYWAY_HOME}/flyway \
                        -url="jdbc:singlestore://${DB_HOST}:${DB_PORT}/${DB_NAME}" \
                        -user="${env.DB_USER}" \
                        -password="${env.DB_PASS}" \
                        -locations="filesystem:${FLYWAY_SQL_DIR}" \
                        -baselineOnMigrate=true \
                        -baselineVersion=0 \
                        -baselineDescription="Flyway_Baseline" \
                        baseline
                    echo "Baseline completed"
                else
                    echo "⏩ flyway_schema_history already exists, Skipping Baseline"
                fi
            """
        }
    }
}
   
   
   stage('Flyway Dry Run') {
            steps {
                script {
                    echo "========== STAGE 7: Flyway Dry Run =========="

                    sh """
                        #!/bin/bash
                        set -e

                        DRYRUN_FILE="${FLYWAY_SNAPSHOT}/flyway_dryrun_\$(date +%Y%m%d_%H%M%S).sql"

                        echo "--- Running Flyway Info ---"
                        ${FLYWAY_HOME}/flyway \
                            -url="jdbc:singlestore://${DB_HOST}:${DB_PORT}/${DB_NAME}" \
                            -user="${env.DB_USER}" \
                            -password="${env.DB_PASS}" \
                            -locations="filesystem:${FLYWAY_SQL_DIR}" \
                            info

                        echo "Flyway Info completed"

                    #    echo "--- Running Flyway Dry Run ---"
                        # Dry run generates SQL script without applying to DB
                      #  ${FLYWAY_HOME}/flyway \
                     #       -url="jdbc:singlestore://${DB_HOST}:${DB_PORT}/${DB_NAME}" \
                    #        -user="${env.DB_USER}" \
                        #    -password="${env.DB_PASS}" \
                       #     -locations="filesystem:${FLYWAY_SQL_DIR}" \
                      #      -dryRunOutput="\$DRYRUN_FILE" \
                    #        migrate

                       # echo "Dry run completed. Output saved at: \$DRYRUN_FILE"

                      #  echo "--- Reading Dry Run Output File ---"
                       # echo "============================================"
                      #  cat \$DRYRUN_FILE
                         echo "============================================"

                        # Save dry run file path for reference
                      #     echo \$DRYRUN_FILE > ${FLYWAY_SNAPSHOT}/dryrun_path.txt
                     """
                }
            }
        }
         stage('Flyway Actual Migration') {
            steps {
                script {
                    echo "========== STAGE 8: Performing Actual Migration =========="

                    sh """
                        #!/bin/bash
                        set -e

                        echo "--- Running Flyway Migrate ---"

                        ${FLYWAY_HOME}/flyway \
                            -url="jdbc:singlestore://${DB_HOST}:${DB_PORT}/${DB_NAME}" \
                            -user="${env.DB_USER}" \
                            -password="${env.DB_PASS}" \
                            -locations="filesystem:${FLYWAY_SQL_DIR}" \
                            -outOfOrder=false \
                            -validateOnMigrate=true \
                            migrate

                        echo "Flyway migration completed successfully"
                    """
                }
            }
        }
        
         stage('Take Post-Migration DB Snapshot') {
            steps {
                script {
                    echo "========== STAGE 9: Taking Post-Migration DB Snapshot =========="

                    sh """
                        #!/bin/bash
                        set -e

                        POST_SNAPSHOT_FILE="${FLYWAY_SNAPSHOT}/post_migration_snapshot_\$(date +%Y%m%d_%H%M%S).sql"

                        echo "--- Taking post-migration snapshot of database: ${DB_NAME} ---"

                        # Using mysqldump to take post-migration snapshot
                        mysqldump \
                            -h ${DB_HOST} \
                            -P ${DB_PORT} \
                            -u ${env.DB_USER} \
                            -p${env.DB_PASS} \
                            --no-data \
                            --routines \
                            --triggers \
                            ${DB_NAME} > \$POST_SNAPSHOT_FILE

                        echo "Post-migration snapshot saved at: \$POST_SNAPSHOT_FILE"
                        ls -lh \$POST_SNAPSHOT_FILE

                        # Save snapshot filename for later reference
                        echo \$POST_SNAPSHOT_FILE > ${FLYWAY_SNAPSHOT}/post_snapshot_path.txt
                    """
                }
            }
        }
        
         stage('Post-Migration DB Status Check') {
            steps {
                script {
                    echo "========== STAGE 11: Post-Migration DB Status Check =========="

                    sh """
                        #!/bin/bash
                        set -e

                        echo "--- Running Flyway Info (Post Migration) ---"

                        ${FLYWAY_HOME}/flyway \
                            -url="jdbc:singlestore://${DB_HOST}:${DB_PORT}/${DB_NAME}" \
                            -user="${env.DB_USER}" \
                            -password="${env.DB_PASS}" \
                            -locations="filesystem:${FLYWAY_SQL_DIR}" \
                            info

                        echo "Post-migration DB status check completed"
                    """
                }
            }
        }
       
       
        
        
         
    }
    
    post {
        success {
            echo " ========== PIPELINE COMPLETED SUCCESSFULLY =========="
            echo "All 1stages executed without errors"
            echo "Database migration completed for: ${DB_NAME}"
        }
        failure {
            echo " ========== PIPELINE FAILED =========="
            echo " Check logs above for error details .."
            echo "  Consider running Flyway Undo to rollback changes"
        }
        always {
            echo " ========== PIPELINE SUMMARY =========="
            echo "Build Number  : ${BUILD_NUMBER}"
            echo "Build URL     : ${BUILD_URL}"
            echo "Database      : ${DB_NAME}"
            echo "Git Branch    : ${GIT_BRANCH}"

        }
    }
    
}
