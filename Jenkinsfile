pipeline{
    agent {label 'fly_way'}
    stages{
        stage('github pull'){
            steps{
                echo "pulling the sql code"
                git url : "https://github.com/Hritick-9/sql_flyway" , branch : "main"
                echo "done pulling code"
            }
            
        }
            stage('database migration status'){
                steps{
                    
                    echo "checking the status"
                    withCredentials([string(credentialsId:'DB_URL' , variable:'db_url'),string(credentialsId:'DB_PASS',variable:'db_pass')]){
                     sh '''
                        flyway \
                        -url="jdbc:singlestore:${db_url}" \
                        -user="root" \
                        -password="${db_pass}" \
                        -locations="filesystem:${WORKSPACE}/" \
                        -schemas="mydb" \
                        info
                    '''
                    }
                    echo "done info"
                }
                
            }
                stage("Migrate"){
                    steps {
                    echo "Migrating"
                     withCredentials([string(credentialsId:'DB_URL' , variable:'db_url'),string(credentialsId:'DB_PASS',variable:'db_pass')]){
                     sh '''
                        flyway \
                        -url="jdbc:singlestore:${db_url}" \
                        -user="root" \
                        -password="${db_pass}" \
                        -locations="filesystem:${WORKSPACE}/" \
                        migrate
                    '''
                    }
                    echo "migrated "
                    }
                    
               
                    
                
            }
            stage ("Check chnages"){
                   steps {
                       echo "listed below the new db table"
                      withCredentials([string(credentialsId:'DB_URL' , variable:'db_url'),string(credentialsId:'DB_PASS',variable:'db_pass')]){
                     sh '''
                        flyway \
                        -url="jdbc:singlestore:${db_url}" \
                        -user="root" \
                        -password="${db_pass}" \
                        -locations="filesystem:${WORKSPACE}/" \
                        -schemas="mydb" \
                        info
                    '''
                    }
                   }
               }
   
        }
}
