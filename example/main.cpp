#include <iostream>
#include <opencv2/opencv.hpp>
#include <cstring>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>

using namespace std;
using namespace cv;

int main()
{
    VideoCapture vid(0);
    Mat frame;

    // Create socket
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock == -1)
    {
        cerr << "Failed to create socket" << endl;
        return 1;
    }

    // Prepare the server address structure
    struct sockaddr_in server_address;
    server_address.sin_family = AF_INET;
    server_address.sin_port = htons(18765); // Server port
    inet_pton(AF_INET, "10.1.2.66", &server_address.sin_addr); // Server IP

    // Connect to the server
    if (connect(sock, (struct sockaddr *)&server_address, sizeof(server_address)) < 0) 
    {
        cerr << "Connection failed" << endl;
        return 1;
    }
    
    while(1)
    {
        vid.read(frame);
        // imshow("Test", frame);
        vector<uint8_t> buffer;
        imencode(".jpg", frame, buffer, {IMWRITE_JPEG_QUALITY, 80});
        if (send(sock, buffer.data(), buffer.size(), 0) < 0) 
        {
            cerr << "Error sending frame" << endl;
        }
        waitKey(1);
    }
    close(sock);
    return 0;
}
