pipeline {
    agent any 
    stages {
        stage('Stage 1') {
            steps {
                echo 'Hello world!' 
                sh 'find . type -d -iname "bobo"'
                sh ' touch roma/bobo.txt'
            }
        }
    }
}
